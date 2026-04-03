// @testmode wasi
import Iter "mo:core@2.4/Iter";
import Debug "mo:core@2.4/Debug";
import Text "mo:core@2.4/Text";
import Buffer "mo:base@0.16/Buffer";
import Array "mo:core@2.4/Array";
import Blob "mo:core@2.4/Blob";
import Principal "mo:core@2.4/Principal";
import Int "mo:core@2.4/Int";
import Nat "mo:core@2.4/Nat";
import Nat8 "mo:core@2.4/Nat8";
import Nat16 "mo:core@2.4/Nat16";
import Nat32 "mo:core@2.4/Nat32";
import Nat64 "mo:core@2.4/Nat64";
import Float "mo:core@2.4/Float";

import Fuzz "mo:fuzz";
import Itertools "mo:itertools@0.2.2/Iter";
import Runtime "mo:core/Runtime";

import { test; suite } "mo:test";
import Serde "../src";
import CandidEncoder "../src/Candid/Blob/Encoder";
import CandidDecoder "../src/Candid/Blob/Decoder";

import TestUtils "CandidTestUtils";

type Candid = Serde.Candid;

func createGenerator(seed : Nat) : { next() : Nat } {
    var state : Nat64 = Nat64.fromNat(seed);
    if (state == 0) state := 1;
    {
        next = func() : Nat {
            state ^= state << 13 : Nat64;
            state ^= state >> 7 : Nat64;
            state ^= state << 17 : Nat64;
            Nat64.toNat(state);
        };
    };
};

let fuzz = Fuzz.create(createGenerator(42));
let limit = 100;

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

let option_nat_values = Buffer.Buffer<?Nat>(limit);
let option_text_values = Buffer.Buffer<?Text>(limit);
let array_nat8_values = Buffer.Buffer<[Nat8]>(limit);
let array_text_values = Buffer.Buffer<[Text]>(limit);

type SimpleRecord = { id : Nat; name : Text; active : Bool };
type NestedRecord = {
    user : SimpleRecord;
    metadata : { created : Int; tags : [Text] };
    settings : ?{ theme : Text; notifications : Bool };
};
type MixedTuple = (Nat, Text, Bool, ?Float);
type SimpleVariant = { #success : Nat; #error : Text; #pending };
type ComplexVariant = { #user : SimpleRecord; #admin : NestedRecord; #guest };

let simple_record_values = Buffer.Buffer<SimpleRecord>(limit);
let nested_record_values = Buffer.Buffer<NestedRecord>(limit);
let mixed_tuple_values = Buffer.Buffer<MixedTuple>(limit);
let simple_variant_values = Buffer.Buffer<SimpleVariant>(limit);
let complex_variant_values = Buffer.Buffer<ComplexVariant>(limit);

let large_text_values = Buffer.Buffer<Text>(limit);
let large_array_values = Buffer.Buffer<[Nat]>(limit);
let deep_nesting_values = Buffer.Buffer<Candid>(limit);
let wide_record_values = Buffer.Buffer<Candid>(limit);

let random_principal = fuzz.principal.randomPrincipal(29);

for (i in Itertools.range(0, limit)) {
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

    option_nat_values.add(if (fuzz.bool.random()) ?nat else null);
    option_text_values.add(if (fuzz.bool.random()) ?text else null);

    array_nat8_values.add(fuzz.array.randomArray<Nat8>(fuzz.nat.randomRange(3, 10), func() : Nat8 = nat8));
    array_text_values.add(fuzz.array.randomArray<Text>(fuzz.nat.randomRange(3, 10), func() = text));

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
            case (0) #user({ id = nat; name = text; active = fuzz.bool.random() });
            case (1) #admin({
                user = { id = nat; name = text; active = fuzz.bool.random() };
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


    large_text_values.add(fuzz.text.randomAlphanumeric(fuzz.nat.randomRange(1000, 5000)));
    large_array_values.add(fuzz.array.randomArray<Nat>(fuzz.nat.randomRange(500, 1000), func() = nat));

    deep_nesting_values.add(#Record([("level1", #Record([("level2", #Record([("level3", #Record([("level4", #Record([("level5", #Nat(nat))]))]))]))]))]));

    wide_record_values.add(
        #Record(Array.tabulate<(Text, Candid)>(20, func(j) = ("field" # Nat.toText(j), #Nat(nat))))
    );
};

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
    var large_text = Buffer.Buffer<Blob>(limit);
    var large_array = Buffer.Buffer<Blob>(limit);
    var deep_nesting = Buffer.Buffer<Blob>(limit);
    var wide_record = Buffer.Buffer<Blob>(limit);
};

let simple_record_field_names = ["id", "name", "active"];
let nested_record_field_names = ["user", "metadata", "settings", "id", "name", "active", "created", "tags", "theme", "notifications"];
let simple_variant_field_names = ["success", "error", "pending"];
let complex_variant_field_names = ["user", "admin", "guest", "id", "name", "active", "metadata", "settings", "created", "tags", "theme", "notifications"];
let deep_nesting_field_names = ["level1", "level2", "level3", "level4", "level5"];
let wide_record_field_names = Array.tabulate<Text>(20, func(j) = "field" # Nat.toText(j));

suite("BenchTypes", func() {

    // ── encode() ──────────────────────────────────────────────────────────────

    suite("encode()", func() {

        test("Nat", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Nat(nat_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.nat, blob);
                encoded_blobs.nat.add(blob);
            };
        });

        test("Nat8", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Nat8(nat8_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.nat8, blob);
                encoded_blobs.nat8.add(blob);
            };
        });

        test("Nat16", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Nat16(nat16_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.nat16, blob);
                encoded_blobs.nat16.add(blob);
            };
        });

        test("Nat32", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Nat32(nat32_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.nat32, blob);
                encoded_blobs.nat32.add(blob);
            };
        });

        test("Nat64", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Nat64(nat64_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.nat64, blob);
                encoded_blobs.nat64.add(blob);
            };
        });

        test("Int", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Int(int_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.int, blob);
                encoded_blobs.int.add(blob);
            };
        });

        test("Int8", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Int8(int8_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.int8, blob);
                encoded_blobs.int8.add(blob);
            };
        });

        test("Int16", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Int16(int16_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.int16, blob);
                encoded_blobs.int16.add(blob);
            };
        });

        test("Int32", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Int32(int32_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.int32, blob);
                encoded_blobs.int32.add(blob);
            };
        });

        test("Int64", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Int64(int64_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.int64, blob);
                encoded_blobs.int64.add(blob);
            };
        });

        test("Float", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Float(float_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.float, blob);
                encoded_blobs.float.add(blob);
            };
        });

        test("Bool", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Bool(bool_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.bool, blob);
                encoded_blobs.bool.add(blob);
            };
        });

        test("Text", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Text(text_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.text, blob);
                encoded_blobs.text.add(blob);
            };
        });

        test("Null", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Null;
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.null_, blob);
            };
        });

        test("Empty", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Empty;
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.empty, blob);
            };
        });

        test("Principal", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Principal(principal_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.principal, blob);
                encoded_blobs.principal.add(blob);
            };
        });

        test("Blob", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Blob(blob_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], primitive_types.blob, blob);
                encoded_blobs.blob.add(blob);
            };
        });

        test("Option(Nat)", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = switch (option_nat_values.get(i)) {
                    case (?n) #Option(#Nat(n));
                    case (null) #Option(#Null);
                };
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding([candid_value], blob);
                encoded_blobs.option_nat.add(blob);
            };
        });

        test("Option(Text)", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = switch (option_text_values.get(i)) {
                    case (?t) #Option(#Text(t));
                    case (null) #Option(#Null);
                };
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding([candid_value], blob);
                encoded_blobs.option_text.add(blob);
            };
        });

        test("Array(Nat8)", func() {
            for (i in Itertools.range(0, limit)) {
                let arr = Array.map<Nat8, Candid>(array_nat8_values.get(i), func(n) = #Nat8(n));
                let candid_value = #Array(arr);
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], compound_types.array_nat8, blob);
                encoded_blobs.array_nat8.add(blob);
            };
        });

        test("Array(Text)", func() {
            for (i in Itertools.range(0, limit)) {
                let arr = Array.map<Text, Candid>(array_text_values.get(i), func(t) = #Text(t));
                let candid_value = #Array(arr);
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], compound_types.array_text, blob);
                encoded_blobs.array_text.add(blob);
            };
        });

        test("Array(Record)", func() {
            for (i in Itertools.range(0, limit)) {
                let record_arr = Array.map<SimpleRecord, Candid>(
                    [simple_record_values.get(i)],
                    func(r) = #Record([("id", #Nat(r.id)), ("name", #Text(r.name)), ("active", #Bool(r.active))]),
                );
                let candid_value = #Array(record_arr);
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], compound_types.array_record, blob);
                encoded_blobs.simple_record.add(blob);
            };
        });

        test("Record(Simple)", func() {
            for (i in Itertools.range(0, limit)) {
                let record = simple_record_values.get(i);
                let candid_value = #Record([("id", #Nat(record.id)), ("name", #Text(record.name)), ("active", #Bool(record.active))]);
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], compound_types.simple_record, blob);
                encoded_blobs.simple_record.add(blob);
            };
        });

        test("Record(Nested)", func() {
            for (i in Itertools.range(0, limit)) {
                let record = nested_record_values.get(i);
                let settings_candid = switch (record.settings) {
                    case (?s) #Option(#Record([("theme", #Text(s.theme)), ("notifications", #Bool(s.notifications))]));
                    case (null) #Option(#Null);
                };

                let candid_value = #Record([
                    ("user", #Record([("id", #Nat(record.user.id)), ("name", #Text(record.user.name)), ("active", #Bool(record.user.active))])),
                    ("metadata", #Record([("created", #Int(record.metadata.created)), ("tags", #Array(Array.map<Text, Candid>(record.metadata.tags, func(t) = #Text(t))))])),
                    ("settings", settings_candid),
                ]);
                
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                Debug.print("formatted type: " # debug_show(formatted_compound_types.nested_record));
                let options = ?{Serde.Candid.defaultOptions with types = ?compound_types.nested_record};

                let split = CandidDecoder.split(blob, ?{Serde.Candid.defaultOptions with types = ?compound_types.nested_record});
                Debug.print("split: " # debug_show(split));
                
                // assert TestUtils.validate_encoding_with_types([candid_value], compound_types.nested_record, blob);
                // assert TestUtils.validate_decoding([candid_value], blob, nested_record_field_names);
                encoded_blobs.nested_record.add(TestUtils.validator_encoding([candid_value]));
                let #ok(decoded_1) = CandidDecoder.one_shot(blob, nested_record_field_names, null) else return assert false;
                // let #ok(decoded_2) = CandidDecoder.one_shot(blob, nested_record_field_names, ?{Serde.Candid.defaultOptions with types = ?compound_types.nested_record}) else return assert false;
            };
        });

        test("Tuple(Mixed)", func() {
            for (i in Itertools.range(0, limit)) {
                let (n, t, b, f) = mixed_tuple_values.get(i);
                let float_opt = switch (f) {
                    case (?fl) #Option(#Float(fl));
                    case (null) #Option(#Null);
                };
                let candid_value = #Tuple([#Nat(n), #Text(t), #Bool(b), float_opt]);
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                // assert TestUtils.validate_encoding_with_types([candid_value], compound_types.tuple_mixed, blob);
                encoded_blobs.mixed_tuple.add(blob);
            };
        });

        test("Variant(Simple)", func() {
            for (i in Itertools.range(0, limit)) {
                let variant_candid = switch (simple_variant_values.get(i)) {
                    case (#success(n)) #Variant(("success", #Nat(n)));
                    case (#error(msg)) #Variant(("error", #Text(msg)));
                    case (#pending) #Variant(("pending", #Null));
                };

                let #ok(blob) = CandidEncoder.one_shot([variant_candid], null);
                // assert TestUtils.validate_encoding_with_types([variant_candid], compound_types.variant_simple, blob);
                encoded_blobs.simple_variant.add(blob);
            };
        });

        test("Variant(Complex)", func() {
            for (i in Itertools.range(0, limit)) {
                let variant_candid = switch (complex_variant_values.get(i)) {
                    case (#user(u)) #Variant(("user", #Record([("id", #Nat(u.id)), ("name", #Text(u.name)), ("active", #Bool(u.active))])));
                    case (#admin(a)) {
                        let settings_candid = switch (a.settings) {
                            case (?s) #Option(#Record([("theme", #Text(s.theme)), ("notifications", #Bool(s.notifications))]));
                            case (null) #Option(#Null);
                        };
                        #Variant(("admin", #Record([
                            ("user", #Record([("id", #Nat(a.user.id)), ("name", #Text(a.user.name)), ("active", #Bool(a.user.active))])),
                            ("metadata", #Record([("created", #Int(a.metadata.created)), ("tags", #Array(Array.map<Text, Candid>(a.metadata.tags, func(t) = #Text(t))))])),
                            ("settings", settings_candid),
                        ])));
                    };
                    case (#guest) #Variant(("guest", #Null));
                };
                let #ok(blob) = CandidEncoder.one_shot([variant_candid], null);
                // assert TestUtils.validate_encoding_with_types([variant_candid], compound_types.variant_complex, blob);
                encoded_blobs.complex_variant.add(blob);
            };
        });

        test("Large Text", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = #Text(large_text_values.get(i));
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                assert TestUtils.validate_encoding_with_types([candid_value], compound_types.large_text, blob);
                encoded_blobs.large_text.add(blob);
            };
        });

        test("Large Array", func() {
            for (i in Itertools.range(0, limit)) {
                let arr = Array.map<Nat, Candid>(large_array_values.get(i), func(n) = #Nat(n));
                let candid_value = #Array(arr);
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                // assert TestUtils.validate_encoding_with_types([candid_value], compound_types.large_array, blob);
                encoded_blobs.large_array.add(blob);
            };
        });

        test("Deep Nesting", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = deep_nesting_values.get(i);
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                // assert TestUtils.validate_encoding_with_types([candid_value], compound_types.deep_nesting, blob);
                encoded_blobs.deep_nesting.add(blob);
            };
        });

        test("Wide Record", func() {
            for (i in Itertools.range(0, limit)) {
                let candid_value = wide_record_values.get(i);
                let #ok(blob) = CandidEncoder.one_shot([candid_value], null);
                // assert TestUtils.validate_encoding_with_types([candid_value], compound_types.wide_record, blob);
                encoded_blobs.wide_record.add(blob);
            };
        });

    });

    // ── decode() ──────────────────────────────────────────────────────────────

    // suite("decode()", func() {

    //     test("Nat", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.nat.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Nat8", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.nat8.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Nat16", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.nat16.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Nat32", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.nat32.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Nat64", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.nat64.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Int", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.int.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Int8", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.int8.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Int16", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.int16.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Int32", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.int32.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Int64", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.int64.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Float", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.float.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Bool", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.bool.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Text", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.text.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Null", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let #ok(blob) = CandidEncoder.one_shot([#Null], null);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Empty", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let #ok(blob) = CandidEncoder.one_shot([#Empty], null);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Principal", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.principal.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Blob", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.blob.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Option(Nat)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.option_nat.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Option(Text)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.option_text.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Array(Nat8)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.array_nat8.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Array(Text)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.array_text.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Array(Record)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.simple_record.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, simple_record_field_names, null);
    //             assert TestUtils.validate_decoding(candid, blob, simple_record_field_names);
    //         };
    //     });

    //     test("Record(Simple)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.simple_record.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, simple_record_field_names, null);
    //             assert TestUtils.validate_decoding(candid, blob, simple_record_field_names);
    //         };
    //     });

    //     test("Record(Nested)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.nested_record.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, nested_record_field_names, null);
    //             assert TestUtils.validate_decoding(candid, blob, nested_record_field_names);
    //         };
    //     });

    //     test("Tuple(Mixed)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.mixed_tuple.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Variant(Simple)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.simple_variant.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, simple_variant_field_names, null);
    //             assert TestUtils.validate_decoding(candid, blob, simple_variant_field_names);
    //         };
    //     });

    //     test("Variant(Complex)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.complex_variant.get(i);
    //             let variant_keys = complex_variant_field_names;
    //             let #ok(candid) = CandidDecoder.one_shot(blob, variant_keys, null);
    //             assert TestUtils.validate_decoding(candid, blob, variant_keys);
    //         };
    //     });

    //     test("Large Text", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.large_text.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Large Array", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.large_array.get(i);
    //             let #ok(candid) = CandidDecoder.one_shot(blob, [], null);
    //             assert TestUtils.validate_decoding(candid, blob, []);
    //         };
    //     });

    //     test("Deep Nesting", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.deep_nesting.get(i);
    //             let record_keys = deep_nesting_field_names;
    //             let #ok(candid) = CandidDecoder.one_shot(blob, record_keys, null);
    //             assert TestUtils.validate_decoding(candid, blob, record_keys);
    //         };
    //     });

    //     test("Wide Record", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.wide_record.get(i);
    //             let record_keys = wide_record_field_names;
    //             let #ok(candid) = CandidDecoder.one_shot(blob, record_keys, null);
    //             assert TestUtils.validate_decoding(candid, blob, record_keys);
    //         };
    //     });

    //     test("Recursive Structure", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let blob = encoded_blobs.deep_nesting.get(i);
    //             let record_keys = deep_nesting_field_names;
    //             let #ok(candid) = CandidDecoder.one_shot(blob, record_keys, null);
    //             assert TestUtils.validate_decoding(candid, blob, record_keys);
    //         };
    //     });

    // });

    // ── encode(sans inference) ────────────────────────────────────────────────

    // suite("encode(sans inference)", func() {

    //     test("Nat", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat };
    //             let #ok(blob) = CandidEncoder.one_shot([#Nat(nat_values.get(i))], ?options);
    //         };
    //     });

    //     test("Nat8", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat8 };
    //             let #ok(blob) = CandidEncoder.one_shot([#Nat8(nat8_values.get(i))], ?options);
    //         };
    //     });

    //     test("Nat16", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat16 };
    //             let #ok(blob) = CandidEncoder.one_shot([#Nat16(nat16_values.get(i))], ?options);
    //         };
    //     });

    //     test("Nat32", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat32 };
    //             let #ok(blob) = CandidEncoder.one_shot([#Nat32(nat32_values.get(i))], ?options);
    //         };
    //     });

    //     test("Nat64", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat64 };
    //             let #ok(blob) = CandidEncoder.one_shot([#Nat64(nat64_values.get(i))], ?options);
    //         };
    //     });

    //     test("Int", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int };
    //             let #ok(blob) = CandidEncoder.one_shot([#Int(int_values.get(i))], ?options);
    //         };
    //     });

    //     test("Int8", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int8 };
    //             let #ok(blob) = CandidEncoder.one_shot([#Int8(int8_values.get(i))], ?options);
    //         };
    //     });

    //     test("Int16", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int16 };
    //             let #ok(blob) = CandidEncoder.one_shot([#Int16(int16_values.get(i))], ?options);
    //         };
    //     });

    //     test("Int32", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int32 };
    //             let #ok(blob) = CandidEncoder.one_shot([#Int32(int32_values.get(i))], ?options);
    //         };
    //     });

    //     test("Int64", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int64 };
    //             let #ok(blob) = CandidEncoder.one_shot([#Int64(int64_values.get(i))], ?options);
    //         };
    //     });

    //     test("Float", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.float };
    //             let #ok(blob) = CandidEncoder.one_shot([#Float(float_values.get(i))], ?options);
    //         };
    //     });

    //     test("Bool", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.bool };
    //             let #ok(blob) = CandidEncoder.one_shot([#Bool(bool_values.get(i))], ?options);
    //         };
    //     });

    //     test("Text", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.text };
    //             let #ok(blob) = CandidEncoder.one_shot([#Text(text_values.get(i))], ?options);
    //         };
    //     });

    //     test("Null", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.null_ };
    //             let #ok(blob) = CandidEncoder.one_shot([#Null], ?options);
    //         };
    //     });

    //     test("Empty", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.empty };
    //             let #ok(blob) = CandidEncoder.one_shot([#Empty], ?options);
    //         };
    //     });

    //     test("Principal", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.principal };
    //             let #ok(blob) = CandidEncoder.one_shot([#Principal(principal_values.get(i))], ?options);
    //         };
    //     });

    //     test("Blob", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.blob };
    //             let #ok(blob) = CandidEncoder.one_shot([#Blob(blob_values.get(i))], ?options);
    //         };
    //     });

    //     test("Option(Nat)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.option_nat };
    //             let #ok(blob) = CandidEncoder.one_shot(
    //                 [
    //                     #Option(switch (option_nat_values.get(i)) {
    //                         case (?n) #Nat(n);
    //                         case (null) #Null;
    //                     })
    //                 ],
    //                 ?options,
    //             );
    //         };
    //     });

    //     test("Option(Text)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.option_text };
    //             let #ok(blob) = CandidEncoder.one_shot(
    //                 [
    //                     #Option(switch (option_text_values.get(i)) {
    //                         case (?t) #Text(t);
    //                         case (null) #Null;
    //                     })
    //                 ],
    //                 ?options,
    //             );
    //         };
    //     });

    //     test("Array(Nat8)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_nat8 };
    //             let arr = Array.map<Nat8, Candid>(array_nat8_values.get(i), func(n) = #Nat8(n));
    //             let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], ?options);
    //         };
    //     });

    //     test("Array(Text)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_text };
    //             let arr = Array.map<Text, Candid>(array_text_values.get(i), func(t) = #Text(t));
    //             let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], ?options);
    //         };
    //     });

    //     test("Array(Record)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_record };
    //             let record_arr = Array.map<SimpleRecord, Candid>(
    //                 [simple_record_values.get(i)],
    //                 func(r) = #Record([("id", #Nat(r.id)), ("name", #Text(r.name)), ("active", #Bool(r.active))]),
    //             );
    //             let #ok(blob) = CandidEncoder.one_shot([#Array(record_arr)], ?options);
    //         };
    //     });

    //     test("Record(Simple)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.simple_record };
    //             let record = simple_record_values.get(i);
    //             let #ok(blob) = CandidEncoder.one_shot(
    //                 [#Record([("id", #Nat(record.id)), ("name", #Text(record.name)), ("active", #Bool(record.active))])],
    //                 ?options,
    //             );
    //         };
    //     });

    //     test("Record(Nested)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.nested_record };
    //             let record = nested_record_values.get(i);
    //             let settings_candid = switch (record.settings) {
    //                 case (?s) #Option(#Record([("theme", #Text(s.theme)), ("notifications", #Bool(s.notifications))]));
    //                 case (null) #Option(#Null);
    //             };
    //             let #ok(blob) = CandidEncoder.one_shot(
    //                 [
    //                     #Record([
    //                         ("user", #Record([("id", #Nat(record.user.id)), ("name", #Text(record.user.name)), ("active", #Bool(record.user.active))])),
    //                         ("metadata", #Record([("created", #Int(record.metadata.created)), ("tags", #Array(Array.map<Text, Candid>(record.metadata.tags, func(t) = #Text(t))))])),
    //                         ("settings", settings_candid),
    //                     ])
    //                 ],
    //                 ?options,
    //             );
    //         };
    //     });

    //     test("Tuple(Mixed)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.tuple_mixed };
    //             let (n, t, b, f) = mixed_tuple_values.get(i);
    //             let float_opt = switch (f) {
    //                 case (?fl) #Option(#Float(fl));
    //                 case (null) #Option(#Null);
    //             };
    //             let #ok(blob) = CandidEncoder.one_shot([#Tuple([#Nat(n), #Text(t), #Bool(b), float_opt])], ?options);
    //         };
    //     });

    //     test("Variant(Simple)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.variant_simple };
    //             let variant_candid = switch (simple_variant_values.get(i)) {
    //                 case (#success(n)) #Variant(("success", #Nat(n)));
    //                 case (#error(msg)) #Variant(("error", #Text(msg)));
    //                 case (#pending) #Variant(("pending", #Null));
    //             };
    //             let #ok(blob) = CandidEncoder.one_shot([variant_candid], ?options);
    //         };
    //     });

    //     test("Variant(Complex)", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.variant_complex };
    //             let variant_candid = switch (complex_variant_values.get(i)) {
    //                 case (#user(u)) #Variant(("user", #Record([("id", #Nat(u.id)), ("name", #Text(u.name)), ("active", #Bool(u.active))])));
    //                 case (#admin(a)) {
    //                     let settings_candid = switch (a.settings) {
    //                         case (?s) #Option(#Record([("theme", #Text(s.theme)), ("notifications", #Bool(s.notifications))]));
    //                         case (null) #Option(#Null);
    //                     };
    //                     #Variant(("admin", #Record([
    //                         ("user", #Record([("id", #Nat(a.user.id)), ("name", #Text(a.user.name)), ("active", #Bool(a.user.active))])),
    //                         ("metadata", #Record([("created", #Int(a.metadata.created)), ("tags", #Array(Array.map<Text, Candid>(a.metadata.tags, func(t) = #Text(t))))])),
    //                         ("settings", settings_candid),
    //                     ])));
    //                 };
    //                 case (#guest) #Variant(("guest", #Null));
    //             };
    //             let #ok(blob) = CandidEncoder.one_shot([variant_candid], ?options);
    //         };
    //     });

    //     test("Large Text", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.large_text };
    //             let #ok(blob) = CandidEncoder.one_shot([#Text(large_text_values.get(i))], ?options);
    //         };
    //     });

    //     test("Large Array", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.large_array };
    //             let arr = Array.map<Nat, Candid>(large_array_values.get(i), func(n) = #Nat(n));
    //             let #ok(blob) = CandidEncoder.one_shot([#Array(arr)], ?options);
    //         };
    //     });

    //     test("Deep Nesting", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.deep_nesting };
    //             let #ok(blob) = CandidEncoder.one_shot([deep_nesting_values.get(i)], ?options);
    //         };
    //     });

    //     test("Wide Record", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.wide_record };
    //             let #ok(blob) = CandidEncoder.one_shot([wide_record_values.get(i)], ?options);
    //         };
    //     });

    //     test("Recursive Structure", func() {
    //         for (i in Itertools.range(0, limit)) {
    //             let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.deep_nesting };
    //             let #ok(blob) = CandidEncoder.one_shot([deep_nesting_values.get(i)], ?options);
    //         };
    //     });

    // });

    // ── decode(sans inference) ────────────────────────────────────────────────

    suite("decode(sans inference)", func() {

        // test("Nat", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat.get(i), [], ?options);
        //     };
        // });

        // test("Nat8", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat8 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat8.get(i), [], ?options);
        //     };
        // });

        // test("Nat16", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat16 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat16.get(i), [], ?options);
        //     };
        // });

        // test("Nat32", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat32 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat32.get(i), [], ?options);
        //     };
        // });

        // test("Nat64", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.nat64 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nat64.get(i), [], ?options);
        //     };
        // });

        // test("Int", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int.get(i), [], ?options);
        //     };
        // });

        // test("Int8", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int8 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int8.get(i), [], ?options);
        //     };
        // });

        // test("Int16", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int16 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int16.get(i), [], ?options);
        //     };
        // });

        // test("Int32", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int32 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int32.get(i), [], ?options);
        //     };
        // });

        // test("Int64", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.int64 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.int64.get(i), [], ?options);
        //     };
        // });

        // test("Float", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.float };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.float.get(i), [], ?options);
        //     };
        // });

        // test("Bool", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.bool };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.bool.get(i), [], ?options);
        //     };
        // });

        // test("Text", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.text };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.text.get(i), [], ?options);
        //     };
        // });

        // test("Null", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.null_ };
        //         let #ok(blob) = CandidEncoder.one_shot([#Null], ?options);
        //         let #ok(candid) = CandidDecoder.one_shot(blob, [], ?options);
        //     };
        // });

        // test("Empty", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.empty };
        //         let #ok(blob) = CandidEncoder.one_shot([#Empty], ?options);
        //         let #ok(candid) = CandidDecoder.one_shot(blob, [], ?options);
        //     };
        // });

        // test("Principal", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.principal };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.principal.get(i), [], ?options);
        //     };
        // });

        // test("Blob", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_primitive_types.blob };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.blob.get(i), [], ?options);
        //     };
        // });

        // test("Option(Nat)", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.option_nat };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.option_nat.get(i), [], ?options);
        //     };
        // });

        // test("Option(Text)", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.option_text };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.option_text.get(i), [], ?options);
        //     };
        // });

        // test("Array(Nat8)", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_nat8 };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.array_nat8.get(i), [], ?options);
        //     };
        // });

        // test("Array(Text)", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_text };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.array_text.get(i), [], ?options);
        //     };
        // });

        // test("Array(Record)", func() {
        //     for (i in Itertools.range(0, limit)) {
        //         let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.array_record };
        //         let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_record.get(i), simple_record_field_names, ?options);
        //     };
        // });

        test("Record(Simple)", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.simple_record };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_record.get(i), simple_record_field_names, ?options);
            };
        });

        test("Record(Nested)", func() {
            Debug.print("formatted type: " # debug_show(?formatted_compound_types.nested_record));
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.nested_record };
                Debug.print("Encodded blob: " # debug_show(i, encoded_blobs.nested_record.get(i)));
                let split = CandidDecoder.split(encoded_blobs.nested_record.get(i), ?options);
                Debug.print("Split blob: " # debug_show(split));
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.nested_record.get(i), nested_record_field_names, ?options);
            };
        });

        test("Tuple(Mixed)", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.tuple_mixed };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.mixed_tuple.get(i), [], ?options);
            };
        });

        test("Variant(Simple)", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.variant_simple };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.simple_variant.get(i), [], ?options);
            };
        });

        test("Variant(Complex)", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.variant_complex };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.complex_variant.get(i), [], ?options);
            };
        });

        test("Large Text", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.large_text };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.large_text.get(i), [], ?options);
            };
        });

        test("Large Array", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.large_array };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.large_array.get(i), [], ?options);
            };
        });

        test("Deep Nesting", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.deep_nesting };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.deep_nesting.get(i), deep_nesting_field_names, ?options);
            };
        });

        test("Wide Record", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.wide_record };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.wide_record.get(i), wide_record_field_names, ?options);
            };
        });

        test("Recursive Structure", func() {
            for (i in Itertools.range(0, limit)) {
                let options = { Serde.Candid.defaultOptions with types = ?formatted_compound_types.deep_nesting };
                let #ok(candid) = CandidDecoder.one_shot(encoded_blobs.deep_nesting.get(i), deep_nesting_field_names, ?options);
            };
        });

    });

});
