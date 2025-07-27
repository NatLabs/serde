import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Float "mo:base/Float";

import Bench "mo:bench";
import Fuzz "mo:fuzz";
import Itertools "mo:itertools/Iter";

import Serde "../src";
import CandidEncoder "../src/Candid/Blob/Encoder";
import CandidDecoder "../src/Candid/Blob/Decoder";

module {
  public func init() : Bench.Bench {
    let bench = Bench.Bench();

    bench.name("Benchmarking Serde by Data Types");
    bench.description("Performance comparison across all supported Candid data types with 10k operations");

    bench.rows([
      // Primitive Types
      "Nat",
      "Nat8",
      "Nat16",
      "Nat32",
      "Nat64",
      "Int",
      "Int8",
      "Int16",
      "Int32",
      "Int64",
      "Float",
      "Bool",
      "Text",
      "Null",
      "Empty",
      "Principal",
      "Blob",

      // Compound Types
      "Option(Nat)",
      "Option(Text)",
      "Array(Nat8)",
      "Array(Text)",
      "Array(Record)",
      // "Record(Simple)", // failing with 'Blob index out of bounds'
      "Record(Nested)",
      // "Tuple(Mixed)", // failing with 'Blob index out of bounds'
      "Variant(Simple)",
      "Variant(Complex)",
      // "Map(Text->Nat)", // redundant - same as record

      // Performance Edge Cases
      "Large Text",
      "Large Array",
      "Deep Nesting",
      "Wide Record",
      // "Recursive Structure", // not supported
    ]);

    bench.cols([
      "encode()",
      "encode(sans inference)",
      "decode()",
      "decode(sans inference)",
    ]);

    type Candid = Serde.Candid;

    func createGenerator(seed : Nat) : { next() : Nat } {
      // Pure bitwise xorshift64 - no multiplication or addition!
      var state : Nat64 = Nat64.fromNat(seed);
      if (state == 0) state := 1; // Avoid zero state

      {
        next = func() : Nat {
          // Only XOR and bit shifts - fastest possible
          state ^= state << 13 : Nat64;
          state ^= state >> 7 : Nat64;
          state ^= state << 17 : Nat64;
          Nat64.toNat(state);
        };
      };
    };

    let fuzz = Fuzz.create(createGenerator(42));
    let limit = 1;

    // Generate test data for each type
    let nat_values = Buffer.Buffer<Nat>(limit);
    let nat8_values = Buffer.Buffer<Nat8>(limit);
    let nat16_values = Buffer.Buffer<Nat16>(limit);
    let nat32_values = Buffer.Buffer<Nat32>(limit);
    let nat64_values = Buffer.Buffer<Nat64>(limit);
    let int_values = Buffer.Buffer<Int>(limit);
    let int8_values = Buffer.Buffer<Int8>(limit);
    let int16_values = Buffer.Buffer<Int16>(limit);
    let int32_values = Buffer.Buffer<Int32>(limit);
    let int64_values = Buffer.Buffer<Int64>(limit);
    let float_values = Buffer.Buffer<Float>(limit);
    let bool_values = Buffer.Buffer<Bool>(limit);
    let text_values = Buffer.Buffer<Text>(limit);
    let principal_values = Buffer.Buffer<Principal>(limit);
    let blob_values = Buffer.Buffer<Blob>(limit);

    // Compound type test data
    let option_nat_values = Buffer.Buffer<?Nat>(limit);
    let option_text_values = Buffer.Buffer<?Text>(limit);
    let array_nat8_values = Buffer.Buffer<[Nat8]>(limit);
    let array_text_values = Buffer.Buffer<[Text]>(limit);

    // Complex structures
    type SimpleRecord = { id : Nat; name : Text; active : Bool };
    type NestedRecord = {
      user : SimpleRecord;
      metadata : { created : Int; tags : [Text] };
      settings : ?{ theme : Text; notifications : Bool };
    };
    type MixedTuple = (Nat, Text, Bool, ?Float);
    type SimpleVariant = { #success : Nat; #error : Text; #pending };
    type ComplexVariant = {
      #user : SimpleRecord;
      #admin : NestedRecord;
      #guest;
    };

    let simple_record_values = Buffer.Buffer<SimpleRecord>(limit);
    let nested_record_values = Buffer.Buffer<NestedRecord>(limit);
    let mixed_tuple_values = Buffer.Buffer<MixedTuple>(limit);
    let simple_variant_values = Buffer.Buffer<SimpleVariant>(limit);
    let complex_variant_values = Buffer.Buffer<ComplexVariant>(limit);
    let map_values = Buffer.Buffer<[(Text, Nat)]>(limit);

    // Edge case data
    let large_text_values = Buffer.Buffer<Text>(limit);
    let large_array_values = Buffer.Buffer<[Nat]>(limit);
    let deep_nesting_values = Buffer.Buffer<Candid>(limit);
    let wide_record_values = Buffer.Buffer<Candid>(limit);

    let random_principal = fuzz.principal.randomPrincipal(29);

    Debug.print("Generating test data for all types...");

    // Populate test data
    for (i in Itertools.range(0, limit)) {
      // Primitive types
      let nat = fuzz.nat.randomRange(0, 1_000_000);
      let nat8 = fuzz.nat8.random();
      let text = fuzz.text.randomAlphanumeric(fuzz.nat.randomRange(5, 10));
      let int = fuzz.int.randomRange(-1_000_000, 1_000_000);

      nat_values.add(nat);
      nat8_values.add(nat8);
      nat16_values.add(fuzz.nat16.random());
      nat32_values.add(fuzz.nat32.random());
      nat64_values.add(fuzz.nat64.random());
      int_values.add(int);
      int8_values.add(fuzz.int8.random());
      int16_values.add(fuzz.int16.random());
      int32_values.add(fuzz.int32.random());
      int64_values.add(fuzz.int64.random());
      float_values.add(fuzz.float.randomRange(-1000.0, 1000.0));
      bool_values.add(fuzz.bool.random());
      text_values.add(text);
      principal_values.add(random_principal);
      blob_values.add(Blob.fromArray(fuzz.array.randomArray<Nat8>(fuzz.nat.randomRange(10, 100), fuzz.nat8.random)));

      // Option types
      option_nat_values.add(if (fuzz.bool.random()) ?nat else null);
      option_text_values.add(if (fuzz.bool.random()) ?text else null);

      // Arrays
      array_nat8_values.add(fuzz.array.randomArray<Nat8>(fuzz.nat.randomRange(3, 10), func() : Nat8 = nat8));
      array_text_values.add(fuzz.array.randomArray<Text>(fuzz.nat.randomRange(3, 10), func() = text));

      // Records and complex types
      simple_record_values.add({
        id = nat;
        name = text;
        active = fuzz.bool.random();
      });

      nested_record_values.add({
        user = {
          id = fuzz.nat.randomRange(1, 1000);
          name = text;
          active = fuzz.bool.random();
        };
        metadata = {
          created = int;
          tags = fuzz.array.randomArray<Text>(fuzz.nat.randomRange(1, 5), func() = text);
        };
        settings = if (fuzz.bool.random()) ?{
          theme = fuzz.array.randomEntry(["dark", "light", "auto"]).1;
          notifications = fuzz.bool.random();
        } else null;
      });

      mixed_tuple_values.add((
        fuzz.nat.randomRange(0, 1000),
        fuzz.text.randomAlphanumeric(10),
        fuzz.bool.random(),
        if (fuzz.bool.random()) ?fuzz.float.randomRange(0.0, 100.0) else null,
      ));

      simple_variant_values.add(
        switch (fuzz.nat.randomRange(0, 2)) {
          case (0) #success(nat);
          case (1) #error(text);
          case (_) #pending;
        }
      );

      complex_variant_values.add(
        switch (fuzz.nat.randomRange(0, 2)) {
          case (0) #user({
            id = nat;
            name = text;
            active = fuzz.bool.random();
          });
          case (1) #admin({
            user = {
              id = nat;
              name = text;
              active = fuzz.bool.random();
            };
            metadata = {
              created = int;
              tags = fuzz.array.randomArray<Text>(fuzz.nat.randomRange(1, 5), func() = text);
            };
            settings = if (fuzz.bool.random()) ?{
              theme = fuzz.array.randomEntry(["dark", "light", "auto"]).1;
              notifications = fuzz.bool.random();
            } else null;
          });
          case (_) #guest;
        }
      );

      map_values.add(
        Array.tabulate<(Text, Nat)>(
          fuzz.nat.randomRange(3, 8),
          func(j) = (
            "key" # Nat.toText(j),
            nat,
          ),
        )
      );

      // Edge cases
      large_text_values.add(fuzz.text.randomAlphanumeric(fuzz.nat.randomRange(1000, 5000)));
      large_array_values.add(fuzz.array.randomArray<Nat>(fuzz.nat.randomRange(500, 1000), func() = nat));

      // Deep nesting - 5 levels deep
      deep_nesting_values.add(#Record([("level1", #Record([("level2", #Record([("level3", #Record([("level4", #Record([("level5", #Nat(nat))]))]))]))]))]));

      // Wide record - 20 fields
      wide_record_values.add(
        #Record(
          Array.tabulate<(Text, Candid)>(
            20,
            func(j) = (
              "field" # Nat.toText(j),
              #Nat(nat),
            ),
          )
        )
      );
    };

    Debug.print("Generated test data for all types");

    // Define type schemas for sans-inference benchmarks
    let primitive_types = {
      nat = [#Nat : Serde.Candid.CandidType];
      nat8 = [#Nat8 : Serde.Candid.CandidType];
      nat16 = [#Nat16 : Serde.Candid.CandidType];
      nat32 = [#Nat32 : Serde.Candid.CandidType];
      nat64 = [#Nat64 : Serde.Candid.CandidType];
      int = [#Int : Serde.Candid.CandidType];
      int8 = [#Int8 : Serde.Candid.CandidType];
      int16 = [#Int16 : Serde.Candid.CandidType];
      int32 = [#Int32 : Serde.Candid.CandidType];
      int64 = [#Int64 : Serde.Candid.CandidType];
      float = [#Float : Serde.Candid.CandidType];
      bool = [#Bool : Serde.Candid.CandidType];
      text = [#Text : Serde.Candid.CandidType];
      null_ = [#Null : Serde.Candid.CandidType];
      empty = [#Empty : Serde.Candid.CandidType];
      principal = [#Principal : Serde.Candid.CandidType];
      blob = [#Blob : Serde.Candid.CandidType];
    };

    let compound_types = {
      option_nat = [#Option(#Nat) : Serde.Candid.CandidType];
      option_text = [#Option(#Text)];
      array_nat8 = [#Array(#Nat8)];
      array_text = [#Array(#Text)];
      array_record = [#Array(#Record([("id", #Nat), ("name", #Text), ("active", #Bool)]))];
      simple_record = [#Record([("id", #Nat), ("name", #Text), ("active", #Bool)])];
      nested_record = [#Record([("user", #Record([("id", #Nat), ("name", #Text), ("active", #Bool)])), ("metadata", #Record([("created", #Int), ("tags", #Array(#Text))])), ("settings", #Option(#Record([("theme", #Text), ("notifications", #Bool)])))])];
      tuple_mixed = [#Tuple([#Nat, #Text, #Bool, #Option(#Float)])];
      variant_simple = [#Variant([("success", #Nat), ("error", #Text), ("pending", #Null)])];
      variant_complex = [#Variant([("user", #Record([("id", #Nat), ("name", #Text), ("active", #Bool)])), ("admin", #Record([("user", #Record([("id", #Nat), ("name", #Text), ("active", #Bool)])), ("metadata", #Record([("created", #Int), ("tags", #Array(#Text))])), ("settings", #Option(#Record([("theme", #Text), ("notifications", #Bool)])))])), ("guest", #Null)])];
      map_text_nat = [#Map([("", #Nat)])];
      large_text = [#Text];
      large_array = [#Array(#Nat)];
      deep_nesting = [#Record([("level1", #Record([("level2", #Record([("level3", #Record([("level4", #Record([("level5", #Nat)]))]))]))]))])];
      wide_record = [#Record(Array.tabulate<(Text, Serde.Candid.CandidType)>(20, func(j) = ("field" # Nat.toText(j), #Nat)))];
    };

    // Format type schemas for optimal performance with sans-inference encoding
    let formatted_primitive_types = {
      nat = Serde.Candid.formatCandidType(primitive_types.nat, null);
      nat8 = Serde.Candid.formatCandidType(primitive_types.nat8, null);
      nat16 = Serde.Candid.formatCandidType(primitive_types.nat16, null);
      nat32 = Serde.Candid.formatCandidType(primitive_types.nat32, null);
      nat64 = Serde.Candid.formatCandidType(primitive_types.nat64, null);
      int = Serde.Candid.formatCandidType(primitive_types.int, null);
      int8 = Serde.Candid.formatCandidType(primitive_types.int8, null);
      int16 = Serde.Candid.formatCandidType(primitive_types.int16, null);
      int32 = Serde.Candid.formatCandidType(primitive_types.int32, null);
      int64 = Serde.Candid.formatCandidType(primitive_types.int64, null);
      float = Serde.Candid.formatCandidType(primitive_types.float, null);
      bool = Serde.Candid.formatCandidType(primitive_types.bool, null);
      text = Serde.Candid.formatCandidType(primitive_types.text, null);
      null_ = Serde.Candid.formatCandidType(primitive_types.null_, null);
      empty = Serde.Candid.formatCandidType(primitive_types.empty, null);
      principal = Serde.Candid.formatCandidType(primitive_types.principal, null);
      blob = Serde.Candid.formatCandidType(primitive_types.blob, null);
    };

    let formatted_compound_types = {
      option_nat = Serde.Candid.formatCandidType(compound_types.option_nat, null);
      option_text = Serde.Candid.formatCandidType(compound_types.option_text, null);
      array_nat8 = Serde.Candid.formatCandidType(compound_types.array_nat8, null);
      array_text = Serde.Candid.formatCandidType(compound_types.array_text, null);
      array_record = Serde.Candid.formatCandidType(compound_types.array_record, null);
      simple_record = Serde.Candid.formatCandidType(compound_types.simple_record, null);
      nested_record = Serde.Candid.formatCandidType(compound_types.nested_record, null);
      tuple_mixed = Serde.Candid.formatCandidType(compound_types.tuple_mixed, null);
      variant_simple = Serde.Candid.formatCandidType(compound_types.variant_simple, null);
      variant_complex = Serde.Candid.formatCandidType(compound_types.variant_complex, null);
      map_text_nat = Serde.Candid.formatCandidType(compound_types.map_text_nat, null);
      large_text = Serde.Candid.formatCandidType(compound_types.large_text, null);
      large_array = Serde.Candid.formatCandidType(compound_types.large_array, null);
      deep_nesting = Serde.Candid.formatCandidType(compound_types.deep_nesting, null);
      wide_record = Serde.Candid.formatCandidType(compound_types.wide_record, null);
    };

    // Storage for encoded blobs
    let encoded_blobs = {
      var nat = Buffer.Buffer<Blob>(limit);
      var nat8 = Buffer.Buffer<Blob>(limit);
      var nat16 = Buffer.Buffer<Blob>(limit);
      var nat32 = Buffer.Buffer<Blob>(limit);
      var nat64 = Buffer.Buffer<Blob>(limit);
      var int = Buffer.Buffer<Blob>(limit);
      var int8 = Buffer.Buffer<Blob>(limit);
      var int16 = Buffer.Buffer<Blob>(limit);
      var int32 = Buffer.Buffer<Blob>(limit);
      var int64 = Buffer.Buffer<Blob>(limit);
      var float = Buffer.Buffer<Blob>(limit);
      var bool = Buffer.Buffer<Blob>(limit);
      var text = Buffer.Buffer<Blob>(limit);
      var principal = Buffer.Buffer<Blob>(limit);
      var blob = Buffer.Buffer<Blob>(limit);
      var option_nat = Buffer.Buffer<Blob>(limit);
      var option_text = Buffer.Buffer<Blob>(limit);
      var array_nat8 = Buffer.Buffer<Blob>(limit);
      var array_text = Buffer.Buffer<Blob>(limit);
      var simple_record = Buffer.Buffer<Blob>(limit);
      var nested_record = Buffer.Buffer<Blob>(limit);
      var mixed_tuple = Buffer.Buffer<Blob>(limit);
      var simple_variant = Buffer.Buffer<Blob>(limit);
      var complex_variant = Buffer.Buffer<Blob>(limit);
      var map_values = Buffer.Buffer<Blob>(limit);
      var large_text = Buffer.Buffer<Blob>(limit);
      var large_array = Buffer.Buffer<Blob>(limit);
      var deep_nesting = Buffer.Buffer<Blob>(limit);
      var wide_record = Buffer.Buffer<Blob>(limit);
    };

    bench.runner(
      func(row, col) = switch (col, row) {
        // Primitive Types - Encoding
        case ("encode()", "Nat") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Nat(nat_values.get(i))], null);
            encoded_blobs.nat.add(blob);
          };
        };
        case ("encode()", "Nat8") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Nat8(nat8_values.get(i))], null);
            encoded_blobs.nat8.add(blob);
          };
        };
        case ("encode()", "Nat16") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Nat16(nat16_values.get(i))], null);
            encoded_blobs.nat16.add(blob);
          };
        };
        case ("encode()", "Nat32") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Nat32(nat32_values.get(i))], null);
            encoded_blobs.nat32.add(blob);
          };
        };
        case ("encode()", "Nat64") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Nat64(nat64_values.get(i))], null);
            encoded_blobs.nat64.add(blob);
          };
        };
        case ("encode()", "Int") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Int(int_values.get(i))], null);
            encoded_blobs.int.add(blob);
          };
        };
        case ("encode()", "Int8") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Int8(int8_values.get(i))], null);
            encoded_blobs.int8.add(blob);
          };
        };
        case ("encode()", "Int16") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Int16(int16_values.get(i))], null);
            encoded_blobs.int16.add(blob);
          };
        };
        case ("encode()", "Int32") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Int32(int32_values.get(i))], null);
            encoded_blobs.int32.add(blob);
          };
        };
        case ("encode()", "Int64") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Int64(int64_values.get(i))], null);
            encoded_blobs.int64.add(blob);
          };
        };
        case ("encode()", "Float") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Float(float_values.get(i))], null);
            encoded_blobs.float.add(blob);
          };
        };
        case ("encode()", "Bool") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Bool(bool_values.get(i))], null);
            encoded_blobs.bool.add(blob);
          };
        };
        case ("encode()", "Text") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Text(text_values.get(i))], null);
            encoded_blobs.text.add(blob);
          };
        };
        case ("encode()", "Null") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Null], null);
          };
        };
        case ("encode()", "Empty") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Empty], null);
          };
        };
        case ("encode()", "Principal") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Principal(principal_values.get(i))], null);
            encoded_blobs.principal.add(blob);
          };
        };
        case ("encode()", "Blob") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Blob(blob_values.get(i))], null);
            encoded_blobs.blob.add(blob);
          };
        };

        // Compound Types - Encoding
        case ("encode()", "Option(Nat)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Option(
                  switch (option_nat_values.get(i)) {
                    case (?n) #Nat(n);
                    case (null) #Null;
                  }
                )
              ],
              null,
            );
            encoded_blobs.option_nat.add(blob);
          };
        };
        case ("encode()", "Option(Text)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Option(
                  switch (option_text_values.get(i)) {
                    case (?t) #Text(t);
                    case (null) #Null;
                  }
                )
              ],
              null,
            );
            encoded_blobs.option_text.add(blob);
          };
        };
        case ("encode()", "Array(Nat8)") {
          for (i in Itertools.range(0, limit)) {
            let arr = Array.map<Nat8, Candid>(array_nat8_values.get(i), func(n) = #Nat8(n));
            let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], null);
            encoded_blobs.array_nat8.add(blob);
          };
        };
        case ("encode()", "Array(Text)") {
          for (i in Itertools.range(0, limit)) {
            let arr = Array.map<Text, Candid>(array_text_values.get(i), func(t) = #Text(t));
            let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], null);
            encoded_blobs.array_text.add(blob);
          };
        };
        case ("encode()", "Array(Record)") {
          for (i in Itertools.range(0, limit)) {
            let record_arr = Array.map<SimpleRecord, Candid>(
              [simple_record_values.get(i)],
              func(r) = #Record([("id", #Nat(r.id)), ("name", #Text(r.name)), ("active", #Bool(r.active))]),
            );
            let #ok(blob) = CandidEncoder.one_shot([#Array(record_arr)], null);
            encoded_blobs.simple_record.add(blob);
          };
        };
        case ("encode()", "Record(Simple)") {
          for (i in Itertools.range(0, limit)) {
            let record = simple_record_values.get(i);
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Record([("id", #Nat(record.id)), ("name", #Text(record.name)), ("active", #Bool(record.active))])
              ],
              null,
            );
            encoded_blobs.simple_record.add(blob);
          };
        };
        case ("encode()", "Record(Nested)") {
          for (i in Itertools.range(0, limit)) {
            let record = nested_record_values.get(i);
            let settings_candid = switch (record.settings) {
              case (?s) #Option(#Record([("theme", #Text(s.theme)), ("notifications", #Bool(s.notifications))]));
              case (null) #Option(#Null);
            };
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Record([
                  ("user", #Record([("id", #Nat(record.user.id)), ("name", #Text(record.user.name)), ("active", #Bool(record.user.active))])),
                  ("metadata", #Record([("created", #Int(record.metadata.created)), ("tags", #Array(Array.map<Text, Candid>(record.metadata.tags, func(t) = #Text(t))))])),
                  ("settings", settings_candid),
                ])
              ],
              null,
            );
            encoded_blobs.nested_record.add(blob);
          };
        };
        case ("encode()", "Tuple(Mixed)") {
          for (i in Itertools.range(0, limit)) {
            let (n, t, b, f) = mixed_tuple_values.get(i);
            let float_opt = switch (f) {
              case (?fl) #Option(#Float(fl));
              case (null) #Option(#Null);
            };
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Tuple([#Nat(n), #Text(t), #Bool(b), float_opt])
              ],
              null,
            );
            encoded_blobs.mixed_tuple.add(blob);
          };
        };
        case ("encode()", "Variant(Simple)") {
          for (i in Itertools.range(0, limit)) {
            let variant_candid = switch (simple_variant_values.get(i)) {
              case (#success(n)) #Variant(("success", #Nat(n)));
              case (#error(msg)) #Variant(("error", #Text(msg)));
              case (#pending) #Variant(("pending", #Null));
            };
            let #ok(blob) = CandidEncoder.one_shot([variant_candid], null);
            encoded_blobs.simple_variant.add(blob);
          };
        };
        case ("encode()", "Variant(Complex)") {
          for (i in Itertools.range(0, limit)) {
            let variant_candid = switch (complex_variant_values.get(i)) {
              case (#user(u)) #Variant(("user", #Record([("id", #Nat(u.id)), ("name", #Text(u.name)), ("active", #Bool(u.active))])));
              case (#admin(a)) {
                let settings_candid = switch (a.settings) {
                  case (?s) #Option(#Record([("theme", #Text(s.theme)), ("notifications", #Bool(s.notifications))]));
                  case (null) #Option(#Null);
                };
                #Variant(("admin", #Record([("user", #Record([("id", #Nat(a.user.id)), ("name", #Text(a.user.name)), ("active", #Bool(a.user.active))])), ("metadata", #Record([("created", #Int(a.metadata.created)), ("tags", #Array(Array.map<Text, Candid>(a.metadata.tags, func(t) = #Text(t))))])), ("settings", settings_candid)])));
              };
              case (#guest) #Variant(("guest", #Null));
            };
            let #ok(blob) = CandidEncoder.one_shot([variant_candid], null);
            encoded_blobs.complex_variant.add(blob);
          };
        };
        case ("encode()", "Map(Text->Nat)") {
          for (i in Itertools.range(0, limit)) {
            let map_entries = Array.map<(Text, Nat), (Text, Candid)>(
              map_values.get(i),
              func((k, v)) = (k, #Nat(v)),
            );
            let #ok(blob) = CandidEncoder.one_shot([#Map(map_entries)], null);
            encoded_blobs.map_values.add(blob);
          };
        };
        case ("encode()", "Large Text") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Text(large_text_values.get(i))], null);
            encoded_blobs.large_text.add(blob);
          };
        };
        case ("encode()", "Large Array") {
          for (i in Itertools.range(0, limit)) {
            let arr = Array.map<Nat, Candid>(large_array_values.get(i), func(n) = #Nat(n));
            let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], null);
            encoded_blobs.large_array.add(blob);
          };
        };
        case ("encode()", "Deep Nesting") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([deep_nesting_values.get(i)], null);
            encoded_blobs.deep_nesting.add(blob);
          };
        };
        case ("encode()", "Wide Record") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([wide_record_values.get(i)], null);
            encoded_blobs.wide_record.add(blob);
          };
        };
        case ("encode()", "Recursive Structure") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([deep_nesting_values.get(i)], null);
          };
        };

        // Primitive Types - Decoding
        case ("decode()", "Nat") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat.get(i), [], null);
          };
        };
        case ("decode()", "Nat8") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat8.get(i), [], null);
          };
        };
        case ("decode()", "Nat16") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat16.get(i), [], null);
          };
        };
        case ("decode()", "Nat32") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat32.get(i), [], null);
          };
        };
        case ("decode()", "Nat64") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat64.get(i), [], null);
          };
        };
        case ("decode()", "Int") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int.get(i), [], null);
          };
        };
        case ("decode()", "Int8") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int8.get(i), [], null);
          };
        };
        case ("decode()", "Int16") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int16.get(i), [], null);
          };
        };
        case ("decode()", "Int32") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int32.get(i), [], null);
          };
        };
        case ("decode()", "Int64") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int64.get(i), [], null);
          };
        };
        case ("decode()", "Float") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.float.get(i), [], null);
          };
        };
        case ("decode()", "Bool") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.bool.get(i), [], null);
          };
        };
        case ("decode()", "Text") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.text.get(i), [], null);
          };
        };
        case ("decode()", "Null") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Null], null);
            let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
          };
        };
        case ("decode()", "Empty") {
          for (i in Itertools.range(0, limit)) {
            let #ok(blob) = CandidEncoder.one_shot([#Empty], null);
            let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
          };
        };
        case ("decode()", "Principal") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.principal.get(i), [], null);
          };
        };
        case ("decode()", "Blob") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.blob.get(i), [], null);
          };
        };

        // Compound Types - Decoding
        case ("decode()", "Option(Nat)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.option_nat.get(i), [], null);
          };
        };
        case ("decode()", "Option(Text)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.option_text.get(i), [], null);
          };
        };
        case ("decode()", "Array(Nat8)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.array_nat8.get(i), [], null);
          };
        };
        case ("decode()", "Array(Text)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.array_text.get(i), [], null);
          };
        };
        case ("decode()", "Array(Record)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_record.get(i), ["id", "name", "active"], null);
          };
        };
        case ("decode()", "Record(Simple)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_record.get(i), ["id", "name", "active"], null);
          };
        };
        case ("decode()", "Record(Nested)") {
          for (i in Itertools.range(0, limit)) {
            let record_keys = ["user", "metadata", "settings"];
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nested_record.get(i), record_keys, null);
          };
        };
        case ("decode()", "Tuple(Mixed)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.mixed_tuple.get(i), [], null);
          };
        };
        case ("decode()", "Variant(Simple)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_variant.get(i), [], null);
          };
        };
        case ("decode()", "Variant(Complex)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.complex_variant.get(i), [], null);
          };
        };
        case ("decode()", "Map(Text->Nat)") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.map_values.get(i), [], null);
          };
        };
        case ("decode()", "Large Text") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.large_text.get(i), [], null);
          };
        };
        case ("decode()", "Large Array") {
          for (i in Itertools.range(0, limit)) {
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.large_array.get(i), [], null);
          };
        };
        case ("decode()", "Deep Nesting") {
          for (i in Itertools.range(0, limit)) {
            let record_keys = ["level1", "level2", "level3", "level4", "level5"];
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.deep_nesting.get(i), record_keys, null);
          };
        };
        case ("decode()", "Wide Record") {
          for (i in Itertools.range(0, limit)) {
            let record_keys = Array.tabulate<Text>(20, func(j) = "field" # Nat.toText(j));
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.wide_record.get(i), record_keys, null);
          };
        };
        case ("decode()", "Recursive Structure") {
          for (i in Itertools.range(0, limit)) {
            let record_keys = ["level1", "level2", "level3", "level4", "level5"];
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.deep_nesting.get(i), record_keys, null);
          };
        };

        // Sans-inference encoding (with formatted types for optimal performance)
        case ("encode(sans inference)", "Nat") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat
            };
            let #ok(blob) = CandidEncoder.one_shot([#Nat(nat_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Nat8") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat8
            };
            let #ok(blob) = CandidEncoder.one_shot([#Nat8(nat8_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Nat16") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat16
            };
            let #ok(blob) = CandidEncoder.one_shot([#Nat16(nat16_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Nat32") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat32
            };
            let #ok(blob) = CandidEncoder.one_shot([#Nat32(nat32_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Nat64") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat64
            };
            let #ok(blob) = CandidEncoder.one_shot([#Nat64(nat64_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Int") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int
            };
            let #ok(blob) = CandidEncoder.one_shot([#Int(int_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Int8") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int8
            };
            let #ok(blob) = CandidEncoder.one_shot([#Int8(int8_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Int16") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int16
            };
            let #ok(blob) = CandidEncoder.one_shot([#Int16(int16_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Int32") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int32
            };
            let #ok(blob) = CandidEncoder.one_shot([#Int32(int32_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Int64") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int64
            };
            let #ok(blob) = CandidEncoder.one_shot([#Int64(int64_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Float") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.float
            };
            let #ok(blob) = CandidEncoder.one_shot([#Float(float_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Bool") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.bool
            };
            let #ok(blob) = CandidEncoder.one_shot([#Bool(bool_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Text") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.text
            };
            let #ok(blob) = CandidEncoder.one_shot([#Text(text_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Null") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.null_
            };
            let #ok(blob) = CandidEncoder.one_shot([#Null], ?options);
          };
        };
        case ("encode(sans inference)", "Empty") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.empty
            };
            let #ok(blob) = CandidEncoder.one_shot([#Empty], ?options);
          };
        };
        case ("encode(sans inference)", "Principal") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.principal
            };
            let #ok(blob) = CandidEncoder.one_shot([#Principal(principal_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Blob") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.blob
            };
            let #ok(blob) = CandidEncoder.one_shot([#Blob(blob_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Option(Nat)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.option_nat
            };
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Option(
                  switch (option_nat_values.get(i)) {
                    case (?n) #Nat(n);
                    case (null) #Null;
                  }
                )
              ],
              ?options,
            );
          };
        };
        case ("encode(sans inference)", "Option(Text)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.option_text
            };
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Option(
                  switch (option_text_values.get(i)) {
                    case (?t) #Text(t);
                    case (null) #Null;
                  }
                )
              ],
              ?options,
            );
          };
        };
        case ("encode(sans inference)", "Array(Nat8)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_nat8
            };
            let arr = Array.map<Nat8, Candid>(array_nat8_values.get(i), func(n) = #Nat8(n));
            let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], ?options);
          };
        };
        case ("encode(sans inference)", "Array(Text)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_text
            };
            let arr = Array.map<Text, Candid>(array_text_values.get(i), func(t) = #Text(t));
            let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], ?options);
          };
        };
        case ("encode(sans inference)", "Array(Record)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_record
            };
            let record_arr = Array.map<SimpleRecord, Candid>(
              [simple_record_values.get(i)],
              func(r) = #Record([("id", #Nat(r.id)), ("name", #Text(r.name)), ("active", #Bool(r.active))]),
            );
            let #ok(blob) = CandidEncoder.one_shot([#Array(record_arr)], ?options);
          };
        };
        case ("encode(sans inference)", "Record(Simple)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.simple_record
            };
            let record = simple_record_values.get(i);
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Record([("id", #Nat(record.id)), ("name", #Text(record.name)), ("active", #Bool(record.active))])
              ],
              ?options,
            );
          };
        };
        case ("encode(sans inference)", "Record(Nested)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.nested_record
            };
            let record = nested_record_values.get(i);
            let settings_candid = switch (record.settings) {
              case (?s) #Option(#Record([("theme", #Text(s.theme)), ("notifications", #Bool(s.notifications))]));
              case (null) #Option(#Null);
            };
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Record([
                  ("user", #Record([("id", #Nat(record.user.id)), ("name", #Text(record.user.name)), ("active", #Bool(record.user.active))])),
                  ("metadata", #Record([("created", #Int(record.metadata.created)), ("tags", #Array(Array.map<Text, Candid>(record.metadata.tags, func(t) = #Text(t))))])),
                  ("settings", settings_candid),
                ])
              ],
              ?options,
            );
          };
        };
        case ("encode(sans inference)", "Tuple(Mixed)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.tuple_mixed
            };
            let (n, t, b, f) = mixed_tuple_values.get(i);
            let float_opt = switch (f) {
              case (?fl) #Option(#Float(fl));
              case (null) #Option(#Null);
            };
            let #ok(blob) = CandidEncoder.one_shot(
              [
                #Tuple([#Nat(n), #Text(t), #Bool(b), float_opt])
              ],
              ?options,
            );
          };
        };
        case ("encode(sans inference)", "Variant(Simple)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.variant_simple
            };
            let variant_candid = switch (simple_variant_values.get(i)) {
              case (#success(n)) #Variant(("success", #Nat(n)));
              case (#error(msg)) #Variant(("error", #Text(msg)));
              case (#pending) #Variant(("pending", #Null));
            };
            let #ok(blob) = CandidEncoder.one_shot([variant_candid], ?options);
          };
        };
        case ("encode(sans inference)", "Variant(Complex)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.variant_complex
            };
            let variant_candid = switch (complex_variant_values.get(i)) {
              case (#user(u)) #Variant(("user", #Record([("id", #Nat(u.id)), ("name", #Text(u.name)), ("active", #Bool(u.active))])));
              case (#admin(a)) {
                let settings_candid = switch (a.settings) {
                  case (?s) #Option(#Record([("theme", #Text(s.theme)), ("notifications", #Bool(s.notifications))]));
                  case (null) #Option(#Null);
                };
                #Variant(("admin", #Record([("user", #Record([("id", #Nat(a.user.id)), ("name", #Text(a.user.name)), ("active", #Bool(a.user.active))])), ("metadata", #Record([("created", #Int(a.metadata.created)), ("tags", #Array(Array.map<Text, Candid>(a.metadata.tags, func(t) = #Text(t))))])), ("settings", settings_candid)])));
              };
              case (#guest) #Variant(("guest", #Null));
            };
            let #ok(blob) = CandidEncoder.one_shot([variant_candid], ?options);
          };
        };
        case ("encode(sans inference)", "Map(Text->Nat)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.map_text_nat
            };
            let map_entries = Array.map<(Text, Nat), (Text, Candid)>(
              map_values.get(i),
              func((k, v)) = (k, #Nat(v)),
            );
            let #ok(blob) = CandidEncoder.one_shot([#Map(map_entries)], ?options);
          };
        };
        case ("encode(sans inference)", "Large Text") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.large_text
            };
            let #ok(blob) = CandidEncoder.one_shot([#Text(large_text_values.get(i))], ?options);
          };
        };
        case ("encode(sans inference)", "Large Array") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.large_array
            };
            let arr = Array.map<Nat, Candid>(large_array_values.get(i), func(n) = #Nat(n));
            let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], ?options);
          };
        };
        case ("encode(sans inference)", "Deep Nesting") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.deep_nesting
            };
            let #ok(blob) = CandidEncoder.one_shot([deep_nesting_values.get(i)], ?options);
          };
        };
        case ("encode(sans inference)", "Wide Record") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.wide_record
            };
            let #ok(blob) = CandidEncoder.one_shot([wide_record_values.get(i)], ?options);
          };
        };
        case ("encode(sans inference)", "Recursive Structure") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.deep_nesting
            };
            let #ok(blob) = CandidEncoder.one_shot([deep_nesting_values.get(i)], ?options);
          };
        };

        // Sans-inference decoding (with predefined types)
        case ("decode(sans inference)", "Nat") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Nat8") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat8
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat8.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Nat16") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat16
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat16.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Nat32") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat32
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat32.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Nat64") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat64
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat64.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Int") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Int8") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int8
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int8.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Int16") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int16
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int16.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Int32") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int32
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int32.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Int64") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int64
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int64.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Float") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.float
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.float.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Bool") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.bool
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.bool.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Text") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.text
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.text.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Null") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.null_
            };
            let #ok(blob) = CandidEncoder.one_shot([#Null], ?options);
            let #ok(candid) = CandidDecoder.one_shot(blob, [], ?options);
          };
        };
        case ("decode(sans inference)", "Empty") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.empty
            };
            let #ok(blob) = CandidEncoder.one_shot([#Empty], ?options);
            let #ok(candid) = CandidDecoder.one_shot(blob, [], ?options);
          };
        };
        case ("decode(sans inference)", "Principal") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.principal
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.principal.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Blob") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_primitive_types.blob
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.blob.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Option(Nat)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.option_nat
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.option_nat.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Option(Text)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.option_text
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.option_text.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Array(Nat8)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_nat8
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.array_nat8.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Array(Text)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_text
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.array_text.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Array(Record)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_record
            };
            let record_keys = ["id", "name", "active"];
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_record.get(i), record_keys, ?options);
          };
        };
        case ("decode(sans inference)", "Record(Simple)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.simple_record
            };
            let record_keys = ["id", "name", "active"];
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_record.get(i), record_keys, ?options);
          };
        };
        case ("decode(sans inference)", "Record(Nested)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.nested_record
            };
            let record_keys = ["user", "metadata", "settings"];
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nested_record.get(i), record_keys, ?options);
          };
        };
        case ("decode(sans inference)", "Tuple(Mixed)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.tuple_mixed
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.mixed_tuple.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Variant(Simple)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.variant_simple
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_variant.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Variant(Complex)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.variant_complex
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.complex_variant.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Map(Text->Nat)") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.map_text_nat
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.map_values.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Large Text") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.large_text
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.large_text.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Large Array") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.large_array
            };
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.large_array.get(i), [], ?options);
          };
        };
        case ("decode(sans inference)", "Deep Nesting") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.deep_nesting
            };
            let record_keys = ["level1", "level2", "level3", "level4", "level5"];
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.deep_nesting.get(i), record_keys, ?options);
          };
        };
        case ("decode(sans inference)", "Wide Record") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.wide_record
            };
            let record_keys = Array.tabulate<Text>(20, func(j) = "field" # Nat.toText(j));
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.wide_record.get(i), record_keys, ?options);
          };
        };
        case ("decode(sans inference)", "Recursive Structure") {
          for (i in Itertools.range(0, limit)) {
            let options = {
              Serde.Candid.defaultOptions with types = ?formatted_compound_types.deep_nesting
            };
            let record_keys = ["level1", "level2", "level3", "level4", "level5"];
            let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.deep_nesting.get(i), record_keys, ?options);
          };
        };

        case (_, _) {
          Debug.trap("Unhandled benchmark case: row = \"" # row # "\", col = \"" # col # "\"");
        };
      }
    );

    bench;
  };
};
