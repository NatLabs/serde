import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import Int8 "mo:base/Int8";
import Int32 "mo:base/Int32";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat16 "mo:base/Nat16";
import Int64 "mo:base/Int64";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Order "mo:base/Order";
import Func "mo:base/Func";
import Char "mo:base/Char";
import Int16 "mo:base/Int16";

import Encoder "mo:candid/Encoder";
import Arg "mo:candid/Arg";
import Value "mo:candid/Value";
import Type "mo:candid/Type";
import Tag "mo:candid/Tag";
import Itertools "mo:itertools/Iter";
import PeekableIter "mo:itertools/PeekableIter";
import Map "mo:map/Map";
import FloatX "mo:xtended-numbers/FloatX";
import { hashName = hash_record_key } "mo:candid/Tag";

import T "../Types";
import TrieMap "mo:base/TrieMap";
import Utils "../../Utils";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Tag = Tag.Tag;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<A, B> = Result.Result<A, B>;
    type Buffer<A> = Buffer.Buffer<A>;
    type Hash = Nat32;
    type Map<K, V> = Map.Map<K, V>;
    type Order = Order.Order;

    type Candid = T.Candid;
    type CandidType = T.CandidType;
    type KeyValuePair = T.KeyValuePair;
    let { n32hash; thash } = Map;

    public func encode(candid_values : [Candid], options : ?T.Options) : Result<Blob, Text> {
        // Debug.print("candid_values: " # debug_show candid_values);
        let renaming_map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        // Debug.print("init renaming_map: ");
        ignore do ? {
            let renameKeys = options!.renameKeys;
            for ((k, v) in renameKeys.vals()) {
                renaming_map.put(k, v);
            };
        };

        // Debug.print("filling renaming map");

        let res = toArgs(candid_values, renaming_map);
        // Debug.print("converted to arge");

        let #ok(args) = res else return Utils.send_error(res);
        // Debug.print("extract args from results");

        // Debug.print(debug_show args);
        #ok(Encoder.encode(args));
    };

    public func encodeOne(candid : Candid, options : ?T.Options) : Result<Blob, Text> {
        encode([candid], options);
    };

    func div_ceil(n : Nat, d : Nat) : Nat {
        (n + d - 1) / d;
    };

    // https://en.wikipedia.org/wiki/LEB128
    // limited to 64-bit unsigned integers
    func unsigned_leb128_64(buffer : Buffer<Nat8>, n : Nat) {
        var n64 : Nat64 = Nat64.fromNat(n);

        loop {
            var byte = n64 & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
            n64 >>= 7;

            if (n64 > 0) byte := (byte | 0x80);
            buffer.add(byte);

        } while (n64 > 0);
    };

    // https://en.wikipedia.org/wiki/LEB128
    // func unsigned_leb128(buffer : Buffer<Nat8>, n : Nat) {
    //     if (n == 0) {
    //         buffer.add(0);
    //         return;
    //     };

    //     var words : Buffer<Nat64> = Buffer.Buffer(3);
    //     let bit_buffer = BitBuffer.BitBuffer(128);

    //     var num = n;
    //     let max64 = Nat64.toNat(Nat64.maximumValue);

    //     while (num > 0){
    //         BitBuffer.addNat64(bit_buffer, Nat64.fromNat(num % max64));
    //         num /= max64;
    //     };

    //     let last_word = words.get(words.size() - 1);
    //     let last_word_bit_length = Nat64.toNat(64 - Nat64.bitcountLeadingZero(last_word));
    //     let bit_length = ((words.size() - 1: Nat) * 64) + last_word_bit_length;
    //     let n7bits = div_ceil(bit_length, 7);

    //     var i = 0;
    //     var curr_word = words.get(0);

    //     while (i < n7bits) {
    //         var byte = n64 & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
    //         n64 := n64 >> 7;

    //         byte := if (i == (n7bits - 1)) (byte) else (byte | 0x80);
    //         buffer.add(byte);
    //         i += 1;
    //     };
    // };

    // more = 1;
    // negative = (value < 0);

    // /* the size in bits of the variable value, e.g., 64 if value's type is int64_t */
    // size = no. of bits in signed integer;

    // while (more) {
    // byte = low-order 7 bits of value;
    // value >>= 7;
    // /* the following is only necessary if the implementation of >>= uses a
    //     logical shift rather than an arithmetic shift for a signed left operand */
    // if (negative)
    //     value |= (~0 << (size - 7)); /* sign extend */

    // /* sign bit of byte is second high-order bit (0x40) */
    // if ((value == 0 && sign bit of byte is clear) || (value == -1 && sign bit of byte is set))
    //     more = 0;
    // else
    //     set high-order bit of byte;
    // emit byte;
    // }
    func signed_leb128_64(buffer : Buffer<Nat8>, num : Int) {

        var n64 = Nat64.fromNat(Int.abs(num));
        let bit_length = Nat64.toNat(64 - Nat64.bitcountLeadingZero(n64));
        var n7bits = (bit_length / 7) + 1;

        if (num < 0) {
            var i64 = Nat64.fromNat(Int.abs(num));

            let nbits = (n7bits * 7);

            let mask = (1 << Nat64.fromNat(nbits)) - 1;

            n64 := (mask & (^i64)) + 1;
        };

        loop {
            var byte = n64 & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
            n64 >>= 7;
            n7bits -= 1;

            if (n7bits > 0) byte := (byte | 0x80);
            buffer.add(byte);

        } while (n7bits > 0);

    };

    func infer_candid_types(candid_values : [Candid], renaming_map : TrieMap<Text, Text>) : Result<[CandidType], Text> {
        let buffer = Buffer.Buffer<CandidType>(candid_values.size());

        // Debug.print("convert ... ");
        for (candid in candid_values.vals()) {
            let candid_type = to_candid_types(candid, renaming_map);

            // Debug.print("get internal arg type and value");

            let rows = Buffer.Buffer<[InternalCandidTypeNode]>(8);

            let node : InternalCandidTypeNode = {
                type_ = candid_type;
                height = 0;
                parent_index = 0;
                key = null;
            };
            // Debug.print("init node");

            rows.add([node]);

            order_candid_types_by_height_bfs(rows);
            // Debug.print("order types by height");

            let res = merge_candid_variants_and_array_types(rows);
            // Debug.print("merge variants and array types");
            let #ok(merged_type) = res else return Utils.send_error(res);

            buffer.add(merged_type);
            // Debug.print("add to buffer");
        };

        #ok(Buffer.toArray(buffer));
    };

    let C = {
        COUNTER = {
            COMPOUND_TYPE = 0;
            PRIMITIVE_TYPE = 1;
            VALUE = 2;
        };
    };

    public func one_shot(candid_values : [Candid], options : ?T.Options) : Result<Blob, Text> {

        // Debug.print("candid_values: " # debug_show candid_values);
        let renaming_map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        let compound_type_buffer = Buffer.Buffer<Nat8>(200);
        let primitive_type_buffer = Buffer.Buffer<Nat8>(200);
        let value_buffer = Buffer.Buffer<Nat8>(200);

        // [compound-type-counter, primitive-type-counter, value-counter]
        let counter = [var 0, 0, 0];

        // Debug.print("init renaming_map: ");
        ignore do ? {
            let renameKeys = options!.renameKeys;
            for ((k, v) in renameKeys.vals()) {
                renaming_map.put(k, v);
            };
        };

        var candid_types : [CandidType] = [];

        ignore do ? {
            candid_types := options!.types!;
        };

        if (candid_types.size() == 0) {
            let res = infer_candid_types(candid_values, renaming_map);
            let #ok(inferred_types) = res else return Utils.send_error(res);
            candid_types := inferred_types;
        };

        // Debug.print("candid_types: " # debug_show candid_types);

        one_shot_encode(
            candid_types,
            candid_values,
            compound_type_buffer,
            primitive_type_buffer,
            value_buffer,
            counter,
            renaming_map,
        );

        // Debug.print("done encoding");

        let candid_buffer = Buffer.fromArray<Nat8>([0x44, 0x49, 0x44, 0x4C]); // 'DIDL' magic bytes

        // add compound type to the buffer
        let compound_type_size_bytes = Buffer.Buffer<Nat8>(8);
        unsigned_leb128_64(compound_type_size_bytes, counter[C.COUNTER.COMPOUND_TYPE]);

        // add primitive type to the buffer
        let primitive_type_size_bytes = Buffer.Buffer<Nat8>(8);
        unsigned_leb128_64(primitive_type_size_bytes, counter[C.COUNTER.PRIMITIVE_TYPE]);

        // add value to the buffer
        // unsigned_leb128_64(candid_buffer, counter[C.COUNTER.VALUE]);

        let total_size = candid_buffer.size()
            + compound_type_size_bytes.size()
            + compound_type_buffer.size()
            + primitive_type_size_bytes.size()
            + primitive_type_buffer.size()
            + value_buffer.size();

        let sequence = [
            candid_buffer,
            compound_type_size_bytes,
            compound_type_buffer,
            primitive_type_size_bytes,
            primitive_type_buffer,
            value_buffer,
        ];

        var i = 0;
        var j = 0;

        #ok(
            Blob.fromArray(
                Array.tabulate<Nat8>(
                    total_size,
                    func(_: Nat): Nat8 {
                        var buffer = sequence[i];
                        while (j >= buffer.size()){
                            j := 0;
                            i += 1;
                            buffer := sequence[i];
                        };

                        let byte = buffer.get(j);
                        j+= 1;
                        byte;
                    }
                )
            )
        );
    };

    func tuple_type_to_record(tuple_types : [CandidType]) : [(Text, CandidType)] {
        Array.tabulate<(Text, CandidType)>(
            tuple_types.size(),
            func(i : Nat) : (Text, CandidType) {
                (Char.toText(Char.fromNat32(Nat32.fromNat(i))), tuple_types[i]);
            },
        );
    };

    public func one_shot_encode(
        candid_types : [CandidType],
        candid_values : [Candid],
        compound_type_buffer : Buffer<Nat8>,
        primitive_type_buffer : Buffer<Nat8>,
        value_buffer : Buffer<Nat8>,
        counter : [var Nat],
        renaming_map : TrieMap<Text, Text>,
    ) {
        assert candid_values.size() == candid_types.size();

        // include size of candid values
        // unsigned_leb128_64(type_buffer, candid_values.size());

        let unique_compound_type_map = Map.new<Text, Nat>();
        let recursive_map = Map.new<Text, Text>();

        func encode_nested_type(
            candid_type : CandidType,
            compound_type_buffer : Buffer<Nat8>,
        ) {
            switch (candid_type) {
                case (#Nat) compound_type_buffer.add(T.TypeCode.Nat);
                case (#Nat8) compound_type_buffer.add(T.TypeCode.Nat8);
                case (#Nat16) compound_type_buffer.add(T.TypeCode.Nat16);
                case (#Nat32) compound_type_buffer.add(T.TypeCode.Nat32);
                case (#Nat64) compound_type_buffer.add(T.TypeCode.Nat64);

                case (#Int) compound_type_buffer.add(T.TypeCode.Int);
                case (#Int8) compound_type_buffer.add(T.TypeCode.Int8);
                case (#Int16) compound_type_buffer.add(T.TypeCode.Int16);
                case (#Int32) compound_type_buffer.add(T.TypeCode.Int32);
                case (#Int64) compound_type_buffer.add(T.TypeCode.Int64);

                case (#Float) compound_type_buffer.add(T.TypeCode.Float);
                case (#Bool) compound_type_buffer.add(T.TypeCode.Bool);
                case (#Text) compound_type_buffer.add(T.TypeCode.Text);
                case (#Principal) compound_type_buffer.add(T.TypeCode.Principal);
                case (#Null) compound_type_buffer.add(T.TypeCode.Null);
                case (#Empty) compound_type_buffer.add(T.TypeCode.Empty);

                case (#Option(opt_type)) {
                    compound_type_buffer.add(T.TypeCode.Option);
                    encode_nested_type(opt_type, compound_type_buffer);
                };

                case (#Array(arr_type)) {
                    compound_type_buffer.add(T.TypeCode.Array);
                    encode_nested_type(arr_type, compound_type_buffer);
                };

                case (#Record(field_types)) {
                    compound_type_buffer.add(T.TypeCode.Record);
                    for ((_, field_type) in field_types.vals()) {
                        encode_nested_type(field_type, compound_type_buffer);
                    };
                };

                case (#Variant(variant_types)) {
                    compound_type_buffer.add(T.TypeCode.Variant);
                    for ((_, variant_type) in variant_types.vals()) {
                        encode_nested_type(variant_type, compound_type_buffer);
                    };
                };

                // case (#Recursive(_, recursive_type)) {
                //     compound_type_buffer.add(T.TypeCode.Recursive);
                //     encode_nested_type(recursive_type, compound_type_buffer);
                // };

                case (_) {
                    // Debug.print("unknown type: " # debug_show candid_type);
                };

            };
        };

        func is_compound_type(candid_type : CandidType) : Bool {
            switch (candid_type) {
                case (#Option(_)) true;
                case (#Array(_)) true;
                case (#Record(_)) true;
                case (#Variant(_)) true;
                case (#Recursive(_)) true;
                case (_) false;
            };
        };

        func encode_primitive_type_only(
            candid_type : CandidType,
            compound_type_buffer : Buffer<Nat8>,
            primitive_type_buffer : Buffer<Nat8>,
            is_nested_child_of_compound_type : Bool,

        ) {
            let ref_primitive_type_buffer = if (is_nested_child_of_compound_type) {
                compound_type_buffer;
            } else {
                primitive_type_buffer;
            };

            switch (candid_type) {
                case (#Nat) ref_primitive_type_buffer.add(T.TypeCode.Nat);
                case (#Nat8) ref_primitive_type_buffer.add(T.TypeCode.Nat8);
                case (#Nat16) ref_primitive_type_buffer.add(T.TypeCode.Nat16);
                case (#Nat32) ref_primitive_type_buffer.add(T.TypeCode.Nat32);
                case (#Nat64) ref_primitive_type_buffer.add(T.TypeCode.Nat64);

                case (#Int) ref_primitive_type_buffer.add(T.TypeCode.Int);
                case (#Int8) ref_primitive_type_buffer.add(T.TypeCode.Int8);
                case (#Int16) ref_primitive_type_buffer.add(T.TypeCode.Int16);
                case (#Int32) ref_primitive_type_buffer.add(T.TypeCode.Int32);
                case (#Int64) ref_primitive_type_buffer.add(T.TypeCode.Int64);

                case (#Float) ref_primitive_type_buffer.add(T.TypeCode.Float);
                case (#Bool) ref_primitive_type_buffer.add(T.TypeCode.Bool);
                case (#Text) ref_primitive_type_buffer.add(T.TypeCode.Text);
                case (#Principal) ref_primitive_type_buffer.add(T.TypeCode.Principal);
                case (#Null) ref_primitive_type_buffer.add(T.TypeCode.Null);
                case (#Empty) ref_primitive_type_buffer.add(T.TypeCode.Empty);

                case (_) Debug.trap("encode_primitive_type_only(): unknown primitive type " # debug_show candid_type);
            };
        };

        func encode_compound_type_only(
            candid_type : CandidType,
            compound_type_buffer : Buffer<Nat8>,
            primitive_type_buffer : Buffer<Nat8>,
            unique_compound_type_map : Map<Text, Nat>,
            is_nested_child_of_compound_type : Bool,
        ) {
            let type_info = debug_show candid_type;
            let compound_type_exists = Map.has(unique_compound_type_map, thash, type_info);
            if (compound_type_exists) return;

            ignore Map.put(unique_compound_type_map, thash, type_info, counter[C.COUNTER.COMPOUND_TYPE]);
            counter[C.COUNTER.COMPOUND_TYPE] += 1;

            switch (candid_type) {
                case (#Option(opt_type)) {
                    let opt_type_is_compound = is_compound_type(opt_type);

                    compound_type_buffer.add(T.TypeCode.Option);
                    var forward_ref_index = compound_type_buffer.size();
                    if (opt_type_is_compound) {
                        compound_type_buffer.add(0xff); // placeholder for nested compound type
                    };

                    encode_type_only(
                        opt_type,
                        compound_type_buffer,
                        primitive_type_buffer,
                        unique_compound_type_map,
                        true,
                    );

                    if (opt_type_is_compound) {
                        let opt_type_info = debug_show opt_type;
                        let ?pos = Map.get(unique_compound_type_map, thash, opt_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                        // unsigned_leb128_64(compound_type_buffer, pos);
                        compound_type_buffer.put(forward_ref_index, Nat8.fromNat(pos));
                    };

                };

                case (#Array(arr_type)) {
                    compound_type_buffer.add(T.TypeCode.Array);
                    var forward_ref_index = compound_type_buffer.size();

                    let arr_type_is_compound = is_compound_type(arr_type);
                    if (arr_type_is_compound) {
                        compound_type_buffer.add(0xff); // placeholder for nested compound type
                    };

                    encode_type_only(
                        arr_type,
                        compound_type_buffer,
                        primitive_type_buffer,
                        unique_compound_type_map,
                        true,
                    );

                    if (arr_type_is_compound) {
                        let arr_type_info = debug_show arr_type;
                        let ?pos = Map.get(unique_compound_type_map, thash, arr_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                        // unsigned_leb128_64(compound_type_buffer, pos);
                        compound_type_buffer.put(forward_ref_index, Nat8.fromNat(pos));
                    };
                };

                case (#Record(record_types)) {
                    // let record_buffer = Buffer.Buffer<Nat8>(8); // will be innefficient

                    compound_type_buffer.add(T.TypeCode.Record);
                    unsigned_leb128_64(compound_type_buffer, record_types.size());

                    let sorted_record_types = Array.sort<(Text, CandidType)>(
                        record_types,
                        func((a, _) : (Text, CandidType), (b, _) : (Text, CandidType)) : Order {
                            Text.compare(a, b);
                        },
                    );

                    for ((i, (record_key, value_type)) in Itertools.enumerate(sorted_record_types.vals())) {
                        let value_type_is_compound = is_compound_type(value_type);

                        let hash_key = hash_record_key(record_key);
                        unsigned_leb128_64(compound_type_buffer, Nat32.toNat(hash_key));

                        var forward_ref_index = compound_type_buffer.size();
                        if (value_type_is_compound) {
                            compound_type_buffer.add(0xff); // placeholder for nested compound type
                        };

                        ignore encode_type_only(
                            value_type,
                            compound_type_buffer,
                            primitive_type_buffer,
                            unique_compound_type_map,
                            true,
                        );

                        if (value_type_is_compound) {
                            let value_type_info = debug_show value_type;
                            let ?pos = Map.get(unique_compound_type_map, thash, value_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                            // unsigned_leb128_64(compound_type_buffer, pos);
                            compound_type_buffer.put(forward_ref_index, Nat8.fromNat(pos));
                        };
                    };

                    // compound_type_buffer.append(record_buffer);
                };

                case (#Variant(variant_types)) {
                    compound_type_buffer.add(T.TypeCode.Variant);
                    for ((_, variant_type) in variant_types.vals()) {
                        encode_nested_type(variant_type, compound_type_buffer);
                    };
                };

                case (_) Debug.trap("encode_compound_type_only(): unknown compound type " # debug_show candid_type);
            };
        };

        func encode_type_only(
            candid_type : CandidType,
            compound_type_buffer : Buffer<Nat8>,
            primitive_type_buffer : Buffer<Nat8>,
            unique_compound_type_map : Map<Text, Nat>,
            is_nested_child_of_compound_type : Bool,
        ) {
            if (is_compound_type(candid_type)) {
                encode_compound_type_only(
                    candid_type,
                    compound_type_buffer,
                    primitive_type_buffer,
                    unique_compound_type_map,
                    is_nested_child_of_compound_type,
                );
            } else {
                encode_primitive_type_only(
                    candid_type,
                    compound_type_buffer,
                    primitive_type_buffer,
                    is_nested_child_of_compound_type,
                );
            };
        };

        func encode_primitive_type(
            candid_type : CandidType,
            candid_value : Candid,
            compound_type_buffer : Buffer<Nat8>,
            primitive_type_buffer : Buffer<Nat8>,
            value_buffer : Buffer<Nat8>,
            renaming_map : TrieMap<Text, Text>,
            unique_compound_type_map : Map<Text, Nat>,
            recursive_map : Map<Text, Text>,
            is_nested_child_of_compound_type : Bool,
            ignore_type : Bool,
        ) {
            let ref_primitive_type_buffer = if (ignore_type) {
                object {
                    public func add(_ : Nat8) {}; // do nothing
                };
            } else if (is_nested_child_of_compound_type) {
                compound_type_buffer;
            } else {
                primitive_type_buffer;
            };

            switch (candid_type, candid_value) {
                case (#Nat, #Nat(n)) {
                    // Debug.print("start encoding Nat: " # debug_show n);
                    ref_primitive_type_buffer.add(T.TypeCode.Nat);
                    // Debug.print("encoded type codde");
                    unsigned_leb128_64(value_buffer, n);

                };
                case (#Nat8, #Nat8(n)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Nat8);
                    value_buffer.add(n);
                };
                case (#Nat16, #Nat16(n)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Nat16);
                    value_buffer.add((n & 0xFF) |> Nat16.toNat8(_));
                    value_buffer.add((n >> 8) |> Nat16.toNat8(_));
                };
                case (#Nat32, #Nat32(n)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Nat32);
                    value_buffer.add((n & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add(((n >> 8) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add(((n >> 16) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add((n >> 24) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                };
                case (#Nat64, #Nat64(n)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Nat64);
                    value_buffer.add((n & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 8) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 16) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 24) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 32) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 40) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 48) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add((n >> 56) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                };
                case (#Int, #Int(n)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Int);
                    signed_leb128_64(value_buffer, n);
                };
                case (#Int8, #Int8(i8)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Int8);
                    value_buffer.add(Int8.toNat8(i8));
                };
                case (#Int16, #Int16(i16)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Int16);
                    let n16 = Int16.toNat16(i16);
                    value_buffer.add((n16 & 0xFF) |> Nat16.toNat8(_));
                    value_buffer.add((n16 >> 8) |> Nat16.toNat8(_));
                };
                case (#Int32, #Int32(i32)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Int32);
                    let n = Int32.toNat32(i32);

                    value_buffer.add((n & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add(((n >> 8) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add(((n >> 16) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add((n >> 24) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                };
                case (#Int64, #Int64(i64)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Int64);
                    let n = Int64.toNat64(i64);

                    value_buffer.add((n & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 8) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 16) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 24) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 32) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 40) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 48) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add((n >> 56) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                };
                case (#Float, #Float(f64)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Float);
                    let floatX : FloatX.FloatX = FloatX.fromFloat(f64, #f64);
                    FloatX.encode(value_buffer, floatX, #lsb);
                };
                case (#Bool, #Bool(b)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Bool);
                    value_buffer.add(if (b) (1) else (0));
                };
                case (#Null, #Null) {
                    ref_primitive_type_buffer.add(T.TypeCode.Null);
                };
                case (#Empty, #Empty) {
                    ref_primitive_type_buffer.add(T.TypeCode.Empty);
                };
                case (#Text, #Text(t)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Text);

                    let utf8_bytes = Blob.toArray(Text.encodeUtf8(t));
                    unsigned_leb128_64(value_buffer, utf8_bytes.size());

                    var i = 0;
                    while (i < utf8_bytes.size()) {
                        value_buffer.add(utf8_bytes[i]);
                        i += 1;
                    };

                };
                case (#Principal, #Principal(p)) {
                    ref_primitive_type_buffer.add(T.TypeCode.Principal);

                    value_buffer.add(0x01); // indicate transparency state
                    let bytes = Blob.toArray(Principal.toBlob(p));
                    unsigned_leb128_64(value_buffer, bytes.size());

                    var i = 0;
                    while (i < bytes.size()) {
                        value_buffer.add(bytes[i]);
                        i += 1;
                    };
                };

                case (_) Debug.trap("unknown primitive type: " # debug_show candid_type);
            };
        };

        func encode_compound_type(
            candid_type : CandidType,
            candid_value : Candid,
            compound_type_buffer : Buffer<Nat8>,
            primitive_type_buffer : Buffer<Nat8>,
            value_buffer : Buffer<Nat8>,
            renaming_map : TrieMap<Text, Text>,
            unique_compound_type_map : Map<Text, Nat>,
            recursive_map : Map<Text, Text>,
            is_nested_child_of_compound_type : Bool,
            _type_exists : Bool,
        ) {

            // ----------------- Compound Types ----------------- //

            // encode type only
            // case (candid_type, #Null) {
            //     encode_nested_type(candid_type, compound_type_buffer);
            // };

            let type_info = debug_show candid_type;

            // type_exists_in_compound_type_sequence
            let type_exists = _type_exists or Map.has(unique_compound_type_map, thash, type_info);

            if (not type_exists) {
                ignore Map.put(unique_compound_type_map, thash, type_info, counter[C.COUNTER.COMPOUND_TYPE]);
                counter[C.COUNTER.COMPOUND_TYPE] += 1;
            };

            switch (candid_type, candid_value) {

                case (#Option(opt_type), #Option(opt_value)) {


                    let opt_type_is_compound = is_compound_type(opt_type);

                    if (not type_exists) {
                        compound_type_buffer.add(T.TypeCode.Option);
                    };

                    var forward_ref_index = compound_type_buffer.size();
                    if (not type_exists and opt_type_is_compound) {
                        compound_type_buffer.add(0xff); // placeholder for nested compound type
                    };

                    // added for case where opt_type is neither #Null nor #Option

                    let opt_type_is_not_option = switch (opt_type) {
                        case (#Option(_) or #Null) false;
                        case (_) true;
                    };

                    if (opt_value == #Null and opt_type_is_not_option) {

                        value_buffer.add(0); // no value

                        // a result of being able to set #Null at any point in an #Option type
                        // for instance, type #Option(#Nat) with value #Null
                        if (not type_exists) encode_type_only(
                            opt_type,
                            compound_type_buffer,
                            primitive_type_buffer,
                            unique_compound_type_map,
                            true,
                        );

                    } else {
                        value_buffer.add(1); // has value

                        ignore encode(
                            opt_type,
                            opt_value,
                            compound_type_buffer,
                            primitive_type_buffer,
                            value_buffer,
                            renaming_map,
                            unique_compound_type_map,
                            recursive_map,
                            true,
                            type_exists,
                        );
                    };

                    if (
                        not type_exists and opt_type_is_compound
                    ) {
                        let opt_type_info = debug_show opt_type;
                        let ?pos = Map.get(unique_compound_type_map, thash, opt_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                        // unsigned_leb128_64(compound_type_buffer, pos);
                        compound_type_buffer.put(forward_ref_index, Nat8.fromNat(pos));
                    };

                };

                case (#Option(opt_type), #Null) {
                    value_buffer.add(0); // no value

                    let opt_type_is_compound = is_compound_type(opt_type);

                    if (not type_exists) {
                        compound_type_buffer.add(T.TypeCode.Option);
                    };

                    var forward_ref_index = compound_type_buffer.size();
                    if (not type_exists and opt_type_is_compound) {
                        compound_type_buffer.add(0xff); // placeholder for nested compound type
                    };

                    if (not type_exists) encode_type_only(
                        opt_type,
                        compound_type_buffer,
                        primitive_type_buffer,
                        unique_compound_type_map,
                        true,
                    );

                    if (
                        not type_exists and opt_type_is_compound
                    ) {
                        let opt_type_info = debug_show opt_type;
                        let ?pos = Map.get(unique_compound_type_map, thash, opt_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                        // unsigned_leb128_64(compound_type_buffer, pos);
                        compound_type_buffer.put(forward_ref_index, Nat8.fromNat(pos));
                    };

                };
                case (#Array(arr_type), #Array(arr_values)) {
                    let arr_type_is_compound = is_compound_type(arr_type);

                    if (not type_exists) {
                        compound_type_buffer.add(T.TypeCode.Array);
                    };

                    var forward_ref_index = compound_type_buffer.size();
                    if (not type_exists and arr_type_is_compound) {
                        compound_type_buffer.add(0xff); // placeholder for nested compound type
                        // could be a problem if we have more than 127 compound types
                        // might want to insert instead but that might be costly
                    };

                    unsigned_leb128_64(value_buffer, arr_values.size());

                    var i = 0;

                    if (arr_values.size() == 0 and not type_exists) {
                        encode_type_only(
                            arr_type,
                            compound_type_buffer,
                            primitive_type_buffer,
                            unique_compound_type_map,
                            true,
                        );
                    } else while (i < arr_values.size()) {
                        let val = arr_values[i];

                        ignore encode(
                            arr_type,
                            val,
                            compound_type_buffer,
                            primitive_type_buffer,
                            value_buffer,
                            renaming_map,
                            unique_compound_type_map,
                            recursive_map,
                            true,
                            type_exists or i > 0,
                        );

                        i += 1;
                    };

                    if (not type_exists and arr_type_is_compound) {
                        let arr_type_info = debug_show arr_type;
                        let ?pos = Map.get(unique_compound_type_map, thash, arr_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                        // unsigned_leb128_64(compound_type_buffer, pos);
                        compound_type_buffer.put(forward_ref_index, Nat8.fromNat(pos));
                    };

                };

                case (#Record(record_types), #Record(record_entries)) {

                    let sorted_record_types = Array.sort<(Text, CandidType)>(
                        record_types,
                        func((a, _) : (Text, CandidType), (b, _) : (Text, CandidType)) : Order {
                            Text.compare(a, b);
                        },
                    );

                    let sorted_record_entries = Array.tabulate<(Text, Candid)>(
                        sorted_record_types.size(),
                        func(i : Nat) : (Text, Candid) {
                            let record_key = sorted_record_types[i].0;
                            let ?field_entry = Array.find<(Text, Candid)>(
                                record_entries,
                                func((a, _) : (Text, Candid)) : Bool {
                                    a == record_key;
                                },
                            ) else {
                                // todo: replace traps with Results later
                                // Debug.print("record_key: " # debug_show record_key);
                                // Debug.print("record_types: " # debug_show sorted_record_types);
                                // Debug.print("record_entries: " # debug_show record_entries);
                                Debug.trap("unable to find field key in field types");
                            };

                            field_entry;
                        },
                    );

                    if (not type_exists) {
                        ignore Map.remove(unique_compound_type_map, thash, type_info);
                        counter[C.COUNTER.COMPOUND_TYPE] -= 1;
                    };

                    let zipped_fields = Itertools.zip(sorted_record_types.vals(), sorted_record_entries.vals());

                    for ((i, ((record_key, value_type), (field_key, field_value))) in Itertools.enumerate(zipped_fields)) {
                        assert record_key == field_key;

                        let value_type_is_compound = is_compound_type(value_type);

                        ignore encode(
                            value_type,
                            field_value,
                            compound_type_buffer,
                            primitive_type_buffer,
                            value_buffer,
                            renaming_map,
                            unique_compound_type_map,
                            recursive_map,
                            true,
                            type_exists or not value_type_is_compound, // ignores primitive type but stores its value
                        );
                    };

                    if (not type_exists) {
                        // let sorted_type_info = debug_show sorted_record_types;
                        ignore Map.put(unique_compound_type_map, thash, type_info, counter[C.COUNTER.COMPOUND_TYPE]);
                        counter[C.COUNTER.COMPOUND_TYPE] += 1;
                        compound_type_buffer.add(T.TypeCode.Record);
                        unsigned_leb128_64(compound_type_buffer, record_entries.size());

                        for ((i, (record_key, value_type)) in Itertools.enumerate(sorted_record_types.vals())) {
                            let value_type_is_compound = is_compound_type(value_type);

                            let hash_key = hash_record_key(record_key);
                            unsigned_leb128_64(compound_type_buffer, Nat32.toNat(hash_key));

                            if (value_type_is_compound) {
                                let value_type_info = debug_show value_type;
                                let ?pos = Map.get(unique_compound_type_map, thash, value_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                                // unsigned_leb128_64(record_buffer, pos);
                                compound_type_buffer.add(Nat8.fromNat(pos));
                            } else {
                                encode_primitive_type_only(
                                    value_type,
                                    compound_type_buffer,
                                    primitive_type_buffer,
                                    true,
                                );
                            };
                        };
                    };
                };
                case (#Variant(variant_types), #Variant((variant_key, variant_value))) {

                    let sorted_variant_types = variant_types;
                    // let sorted_variant_types = Array.sort<(Text, CandidType)>(
                    //     variant_types,
                    //     func((a, _) : (Text, CandidType), (b, _) : (Text, CandidType)) : Order {
                    //         Text.compare(a, b);
                    //     },
                    // );

                    let record_buffer = Buffer.Buffer<Nat8>(8); // will be innefficient
                    let ?variant_index = Array.indexOf<(Text, CandidType)>(
                        (variant_key, #Empty),
                        sorted_variant_types,
                        func((a, _) : (Text, CandidType), (b, _) : (Text, CandidType)) : Bool = a == b,
                    ) else Debug.trap("unable to find variant key in variant types");

                    if (not type_exists) {
                        record_buffer.add(T.TypeCode.Variant);
                        unsigned_leb128_64(record_buffer, sorted_variant_types.size());
                    };

                    for ((i, (variant_key, variant_type)) in Itertools.enumerate(sorted_variant_types.vals())) {

                        let variant_type_is_compound = is_compound_type(variant_type);

                        if (not type_exists) {
                            let hash_key = hash_record_key(variant_key);
                            unsigned_leb128_64(record_buffer, Nat32.toNat(hash_key));
                        };

                        if (i == variant_index) {
                            unsigned_leb128_64(value_buffer, i);

                            ignore encode(
                                variant_type,
                                variant_value,
                                if (variant_type_is_compound) compound_type_buffer else record_buffer,
                                primitive_type_buffer,
                                value_buffer,
                                renaming_map,
                                unique_compound_type_map,
                                recursive_map,
                                true,
                                type_exists,
                            );
                        } else encode_type_only(
                            variant_type,
                            if (variant_type_is_compound) compound_type_buffer else record_buffer,
                            primitive_type_buffer,
                            unique_compound_type_map,
                            true,
                        );

                        if (not type_exists and variant_type_is_compound) {
                            let variant_type_info = debug_show variant_type;
                            let ?pos = Map.get(unique_compound_type_map, thash, variant_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                            unsigned_leb128_64(record_buffer, pos);
                        };
                    };

                    compound_type_buffer.append(record_buffer);
                };

                case (_) Debug.trap("invalid (type, value) pair: " # debug_show { candid_type; candid_value });
            };

            // if it is the top level parent and not one of the nested children
            if (not is_nested_child_of_compound_type) {
                let ?pos = Map.get(unique_compound_type_map, thash, type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                unsigned_leb128_64(primitive_type_buffer, pos);
            };

        };

        func encode(
            _candid_type : CandidType,
            _candid_value : Candid,
            compound_type_buffer : Buffer<Nat8>,
            primitive_type_buffer : Buffer<Nat8>,
            value_buffer : Buffer<Nat8>,
            renaming_map : TrieMap<Text, Text>,
            unique_compound_type_map : Map<Text, Nat>,
            recursive_map : Map<Text, Text>,
            _is_nested_child_of_compound_type : Bool,
            ignore_type : Bool,
        ) : ?Hash {

            var candid_type = _candid_type;
            var candid_value = _candid_value;

            // type_exists_in_compound_type_sequence
            var type_exists = ignore_type;


            let type_codes = Buffer.Buffer<Nat8>(8);

            let arrays = Buffer.Buffer<[CandidType]>(8);
            let array_info = Buffer.Buffer<Nat>(8); // array_index;

            let fields = Buffer.Buffer<[(Text, CandidType)]>(8);
            let field_info = Buffer.Buffer<[var Nat]>(8); // [type: record (0) or variant(1), field_index];

            var candid_is_compound_type = true;
            var is_nested_child_of_compound_type = _is_nested_child_of_compound_type;
            Debug.print("new encoding loop");

            label encoding while (candid_is_compound_type) {
                let type_info = debug_show candid_type;
                Debug.print("before is_compound_type: " # debug_show (candid_is_compound_type));

                candid_is_compound_type := is_compound_type(candid_type);
                Debug.print("candid_type: " # debug_show (candid_type));
                Debug.print("is_compound_type: " # debug_show (candid_is_compound_type));
                type_exists := type_exists or Map.has(unique_compound_type_map, thash, type_info);

                // true if candid parent type was a compound type
                is_nested_child_of_compound_type := is_nested_child_of_compound_type or candid_is_compound_type;

                if (not type_exists and candid_is_compound_type) {
                    ignore Map.put(unique_compound_type_map, thash, type_info, counter[C.COUNTER.COMPOUND_TYPE]);
                    counter[C.COUNTER.COMPOUND_TYPE] += 1;
                };

                Debug.print("type_exists: " # debug_show (type_exists));

                // let ref_primitive_type_buffer = compound_type_buffer;

                let ref_primitive_type_buffer = if (type_exists) {
                    object {
                        public func add(_ : Nat8) {}; // do nothing
                    };
                } else compound_type_buffer;

                switch(candid_type){
                    case (#Nat) ref_primitive_type_buffer.add(T.TypeCode.Nat);
                    case (#Nat8) ref_primitive_type_buffer.add(T.TypeCode.Nat8);
                    case (#Nat16,) ref_primitive_type_buffer.add(T.TypeCode.Nat16);
                    case (#Nat32) ref_primitive_type_buffer.add(T.TypeCode.Nat32);
                    case (#Nat64) ref_primitive_type_buffer.add(T.TypeCode.Nat64);
                    case (#Int) ref_primitive_type_buffer.add(T.TypeCode.Int);
                    case (#Int8) ref_primitive_type_buffer.add(T.TypeCode.Int8);
                    case (#Int16) ref_primitive_type_buffer.add(T.TypeCode.Int16);
                    case (#Int32) ref_primitive_type_buffer.add(T.TypeCode.Int32);
                    case (#Int64) ref_primitive_type_buffer.add(T.TypeCode.Int64);
                    case (#Float) ref_primitive_type_buffer.add(T.TypeCode.Float);
                    case (#Bool) ref_primitive_type_buffer.add(T.TypeCode.Bool);
                    case (#Null) ref_primitive_type_buffer.add(T.TypeCode.Null);
                    case (#Empty) ref_primitive_type_buffer.add(T.TypeCode.Empty);
                    case (#Text) ref_primitive_type_buffer.add(T.TypeCode.Text);
                    case (#Principal) ref_primitive_type_buffer.add(T.TypeCode.Principal);

                    // ============= Compound Types ============= //
                    case (#Option(inner_type)){

                        if (not type_exists) {
                            compound_type_buffer.add(T.TypeCode.Option);

                            let inner_type_is_compound = is_compound_type(inner_type);
                            if (inner_type_is_compound){

                                let inner_type_info = debug_show inner_type;

                                let pos = switch(Map.get(unique_compound_type_map, thash, inner_type_info)){
                                    case (?pos) pos;
                                    case (null) counter[C.COUNTER.COMPOUND_TYPE];
                                };

                                unsigned_leb128_64(compound_type_buffer, pos);

                            };
                        };

                        candid_type := inner_type;
                    };

                    case (#Array(inner_type)){

                        if (not type_exists) {
                            compound_type_buffer.add(T.TypeCode.Array);

                            let inner_type_is_compound = is_compound_type(inner_type);
                            if (inner_type_is_compound){

                                let inner_type_info = debug_show inner_type;

                                let pos = switch(Map.get(unique_compound_type_map, thash, inner_type_info)){
                                    case (?pos) pos;
                                    case (null) counter[C.COUNTER.COMPOUND_TYPE];
                                };

                                unsigned_leb128_64(compound_type_buffer, pos);

                            };
                        };

                        candid_type := inner_type;
                    };

                    case (#Record(record_types)) {
                       // field_info.add([var 0, 0]);
                       // fields.add(record_types);
                    };
                    case (#Variant(variant_types)) {
                       // field_info.add([var 1, 0]);
                       // fields.add(variant_types);
                    };
                };

                Debug.print("is_compound_type after switch type: " # debug_show (candid_is_compound_type));


                switch(candid_value){
                    case (#Nat(n)) {
                        unsigned_leb128_64(value_buffer, n);
                    };
                    case (#Nat8(n)) {
                        value_buffer.add(n);
                    };
                    case (#Nat16(n)) {
                        value_buffer.add((n & 0xFF) |> Nat16.toNat8(_));
                        value_buffer.add((n >> 8) |> Nat16.toNat8(_));
                    };
                    case (#Nat32(n)) {
                        value_buffer.add((n & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                        value_buffer.add(((n >> 8) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                        value_buffer.add(((n >> 16) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                        value_buffer.add((n >> 24) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    };
                    case (#Nat64(n)) {
                        value_buffer.add((n & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 8) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 16) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 24) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 32) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 40) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 48) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add((n >> 56) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    };
                    case (#Int(n)) {
                        signed_leb128_64(value_buffer, n);
                    };
                    case (#Int8(i8)) {
                        value_buffer.add(Int8.toNat8(i8));
                    };
                    case (#Int16(i16)) {
                        let n16 = Int16.toNat16(i16);
                        value_buffer.add((n16 & 0xFF) |> Nat16.toNat8(_));
                        value_buffer.add((n16 >> 8) |> Nat16.toNat8(_));
                    };
                    case (#Int32(i32)) {
                        let n = Int32.toNat32(i32);

                        value_buffer.add((n & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                        value_buffer.add(((n >> 8) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                        value_buffer.add(((n >> 16) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                        value_buffer.add((n >> 24) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    };
                    case (#Int64(i64)) {
                        let n = Int64.toNat64(i64);

                        value_buffer.add((n & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 8) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 16) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 24) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 32) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 40) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add(((n >> 48) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                        value_buffer.add((n >> 56) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    };
                    case (#Float(f64)) {
                        let floatX : FloatX.FloatX = FloatX.fromFloat(f64, #f64);
                        FloatX.encode(value_buffer, floatX, #lsb);
                    };
                    case (#Bool(b)) {
                        value_buffer.add(if (b) (1) else (0));
                    };
                    case (#Null) { };
                    case (#Empty) { };
                    case (#Text(t)) {
                        let utf8_bytes = Blob.toArray(Text.encodeUtf8(t));
                        unsigned_leb128_64(value_buffer, utf8_bytes.size());

                        var i = 0;
                        while (i < utf8_bytes.size()) {
                            value_buffer.add(utf8_bytes[i]);
                            i += 1;
                        };

                    };
                    case (#Principal(p)) {
                        value_buffer.add(0x01); // indicate transparency state
                        let bytes = Blob.toArray(Principal.toBlob(p));
                        unsigned_leb128_64(value_buffer, bytes.size());

                        var i = 0;
                        while (i < bytes.size()) {
                            value_buffer.add(bytes[i]);
                            i += 1;
                        };
                    };

                    case (#Option(opt_value)){
                        value_buffer.add(if (opt_value == #Null) (0) else (1));
                        candid_value := opt_value;
                    };

                    case (#Array(arr_values)){
                        unsigned_leb128_64(value_buffer, arr_values.size());

                        var i = 0;
                        let arr_type = candid_type; // extracted inner type earlier in switch(candid_type)

                        while (i < arr_values.size()) {
                            let val = arr_values[i];

                            ignore encode(
                                arr_type,
                                val,
                                compound_type_buffer,
                                primitive_type_buffer,
                                value_buffer,
                                renaming_map,
                                unique_compound_type_map,
                                recursive_map,
                                true,
                                true, // type already added earlier in switch(candid_type)
                            );

                            i += 1;
                        };

                        if (arr_values.size() == 0) {
                            candid_type := arr_type;
                        };

                        candid_value := #Empty;
                    };

                     case (#Record(record_entries)) {
                        let record_types = switch (candid_type) {
                            case (#Record(record_types)) record_types;
                            case (_) Debug.trap("expected record type");
                        };

                        let sorted_record_entries = Array.tabulate<(Text, Candid)>(
                            record_types.size(),
                            func(i : Nat) : (Text, Candid) {
                                let record_key = record_types[i].0;
                                let ?field_entry = Array.find<(Text, Candid)>(
                                    record_entries,
                                    func((a, _) : (Text, Candid)) : Bool {
                                        a == record_key;
                                    },
                                ) else {
                                    // todo: replace traps with Results later
                                    // Debug.print("record_key: " # debug_show record_key);
                                    // Debug.print("record_types: " # debug_show record_types);
                                    // Debug.print("record_entries: " # debug_show record_entries);
                                    Debug.trap("unable to find field key in field types");
                                };

                                field_entry;
                            },
                        );

                        var i = 0;
                        counter[C.COUNTER.COMPOUND_TYPE] -= 1;

                        while (i < record_entries.size()){
                            let record_type = record_types[i].1;
                            let record_key = record_entries[i].0;
                            let record_value = record_entries[i].1;

                            let value_type_is_compound = is_compound_type(record_type);
                            ignore encode(
                                record_type,
                                record_value,
                                compound_type_buffer,
                                primitive_type_buffer,
                                value_buffer,
                                renaming_map,
                                unique_compound_type_map,
                                recursive_map,
                                true,
                                type_exists or not value_type_is_compound, // ignores primitive type but stores its value
                            );
                            i+= 1;
                        };



                            Debug.print("record_types: " # debug_show record_types);

                        if (not type_exists) {
                            compound_type_buffer.add(T.TypeCode.Record);
                            Debug.print("record_types: " # debug_show record_types);

                            unsigned_leb128_64(compound_type_buffer, record_entries.size());

                            Debug.print("record_types: " # debug_show record_types);
                            for ((i, (record_key, value_type)) in Itertools.enumerate(record_types.vals())) {
                                let value_type_is_compound = is_compound_type(value_type);

                                let hash_key = hash_record_key(record_key);
                                unsigned_leb128_64(compound_type_buffer, Nat32.toNat(hash_key));

                                if (value_type_is_compound) {
                                    let value_type_info = debug_show value_type;
                                    let ?pos = Map.get(unique_compound_type_map, thash, value_type_info) else Debug.trap("unable to find compound type pos to store in primitive type sequence");
                                    Debug.print("(pos, value_infor): " # debug_show (pos, value_type_info));
                                    unsigned_leb128_64(compound_type_buffer, pos);
                                } else {
                                    encode_primitive_type_only(
                                        value_type,
                                        compound_type_buffer,
                                        primitive_type_buffer,
                                        true,
                                    );
                                };
                            };
                        };

                        ignore Map.put(unique_compound_type_map, thash, type_info, counter[C.COUNTER.COMPOUND_TYPE]);
                        counter[C.COUNTER.COMPOUND_TYPE] += 1;


                        candid_is_compound_type := false; // end loop
                        candid_type := #Empty;
                        candid_value := #Empty;
                    };

                    case (#Variant(_)){
                    };

                    case (_) {
                        Debug.trap("unsupported type");
                    };
                };

                Debug.print("is_compound_type after switch value: " # debug_show (candid_is_compound_type));


            };

            null;
        };

        Debug.print("candid_values: " # debug_show candid_values);

        for (i in Itertools.range(0, candid_values.size())) {
            counter[C.COUNTER.PRIMITIVE_TYPE] += 1;
            counter[C.COUNTER.VALUE] += 1;

            let candid_type = candid_types[i];
            let candid_is_compound_type = is_compound_type(candid_type);

            ignore encode(
                candid_type,
                candid_values[i],
                if (candid_is_compound_type) compound_type_buffer else primitive_type_buffer,
                primitive_type_buffer,
                value_buffer,
                renaming_map,
                unique_compound_type_map,
                recursive_map,
                false,
                false,
            );

            if (candid_is_compound_type){
                let pos = switch(Map.get(unique_compound_type_map, thash, debug_show candid_type)) {
                    case (?pos) pos;
                    case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence");
                };
                unsigned_leb128_64(primitive_type_buffer, pos);
            };
        };

    };

    type InternalTypeNode = {
        type_ : InternalType;
        height : Nat;
        parent_index : Nat;
        tag : Tag;
    };

    type InternalCandidTypes = {
        #Int;
        #Int8;
        #Int16;
        #Int32;
        #Int64;

        #Nat;
        #Nat8;
        #Nat16;
        #Nat32;
        #Nat64;
        #Bool;
        #Float;
        #Text;
        #Blob;
        #Null;
        #Empty;
        #Principal;

        #Option : InternalCandidTypes;
        #Array : [InternalCandidTypes];
        #Record : [(Text, InternalCandidTypes)];
        #Variant : [(Text, InternalCandidTypes)];
        #Recursive : (Nat, InternalCandidTypes);
    };

    type InternalCandidTypeNode = {
        type_ : InternalCandidTypes;
        height : Nat;
        parent_index : Nat;
        key : ?Text;
    };

    type CandidTypeNode = {
        type_ : CandidType;
        height : Nat;
        parent_index : Nat;
        key : ?Text;
    };

    type TypeNode = {
        type_ : Type;
        height : Nat;
        parent_index : Nat;
        tag : Tag;
    };

    public func toArgs(candid_values : [Candid], renaming_map : TrieMap<Text, Text>) : Result<[Arg], Text> {
        let buffer = Buffer.Buffer<Arg>(candid_values.size());

        // Debug.print("convert ... ");
        for (candid in candid_values.vals()) {
            let (internal_arg_type, arg_value) = toArgTypeAndValue(candid, renaming_map);

            // Debug.print("get internal arg type and value");

            let rows = Buffer.Buffer<[InternalTypeNode]>(8);

            let node : InternalTypeNode = {
                type_ = internal_arg_type;
                height = 0;
                parent_index = 0;
                tag = #name("");
            };
            // Debug.print("init node");

            rows.add([node]);

            order_types_by_height_bfs(rows);
            // Debug.print("order types by height");

            let res = merge_variants_and_array_types(rows);
            // Debug.print("merge variants and array types");
            let #ok(merged_type) = res else return Utils.send_error(res);

            buffer.add({ type_ = merged_type; value = arg_value });
            // Debug.print("add to buffer");
        };

        #ok(Buffer.toArray(buffer));
    };

    type InternalKeyValuePair = { tag : Tag; type_ : InternalType };

    type InternalCompoundType = {
        #opt : InternalType;
        #vector : [InternalType];
        #record : [InternalKeyValuePair];
        #variant : [InternalKeyValuePair];
        // #func_ : Type.FuncType;
        // #service : Type.ServiceType;
        // #recursiveType : { id : Text; type_ : InternalType };
        // #recursiveReference : Text;
    };

    type InternalType = Type.PrimitiveType or InternalCompoundType;

    func toArgTypeAndValue(candid : Candid, renaming_map : TrieMap<Text, Text>) : (InternalType, Value) {
        let (arg_type, arg_value) : (InternalType, Value) = switch (candid) {
            case (#Nat(n)) (#nat, #nat(n));
            case (#Nat8(n)) (#nat8, #nat8(n));
            case (#Nat16(n)) (#nat16, #nat16(n));
            case (#Nat32(n)) (#nat32, #nat32(n));
            case (#Nat64(n)) (#nat64, #nat64(n));

            case (#Int(n)) (#int, #int(n));
            case (#Int8(n)) (#int8, #int8(n));
            case (#Int16(n)) (#int16, #int16(n));
            case (#Int32(n)) (#int32, #int32(n));
            case (#Int64(n)) (#int64, #int64(n));

            case (#Float(n)) (#float64, #float64(n));

            case (#Bool(n)) (#bool, #bool(n));

            case (#Principal(n)) (#principal, #principal(n));

            case (#Text(n)) (#text, #text(n));

            case (#Null) (#null_, #null_);
            case (#Empty) (#empty, #empty);

            case (#Blob(blob)) {
                let bytes = Blob.toArray(blob);
                let inner_values = Array.map(
                    bytes,
                    func(elem : Nat8) : Value {
                        #nat8(elem);
                    },
                );

                (#vector([#nat8]), #vector(inner_values));
            };

            case (#Option(optType)) {
                let (inner_type, inner_value) = toArgTypeAndValue(optType, renaming_map);
                (#opt(inner_type), #opt(inner_value));
            };
            case (#Array(arr)) {
                let inner_types = Buffer.Buffer<InternalType>(arr.size());
                let inner_values = Buffer.Buffer<Value>(arr.size());

                for (item in arr.vals()) {
                    let (inner_type, inner_val) = toArgTypeAndValue(item, renaming_map);
                    inner_types.add(inner_type);
                    inner_values.add(inner_val);
                };

                let types = Buffer.toArray(inner_types);
                let values = Buffer.toArray(inner_values);

                (#vector(types), #vector(values));
            };

            case (#Record(records) or #Map(records)) {
                let types_buffer = Buffer.Buffer<InternalKeyValuePair>(records.size());
                let values_buffer = Buffer.Buffer<RecordFieldValue>(records.size());

                for ((record_key, record_val) in records.vals()) {
                    let (type_, value) = toArgTypeAndValue(record_val, renaming_map);

                    let renamed_key = get_renamed_key(renaming_map, record_key);
                    let tag = generate_key_tag(renamed_key);

                    types_buffer.add({ tag; type_ });
                    values_buffer.add({ tag; value });
                };

                let types = Buffer.toArray(types_buffer);
                let values = Buffer.toArray(values_buffer);

                (#record(types), #record(values));
            };

            case (#Variant((key, val))) {
                let (type_, value) = toArgTypeAndValue(val, renaming_map);

                let renamed_key = get_renamed_key(renaming_map, key);
                let tag = generate_key_tag(renamed_key);

                (#variant([{ tag; type_ }]), #variant({ tag; value }));
            };
        };

        (arg_type, arg_value);
    };

    func to_candid_types(candid : Candid, renaming_map : TrieMap<Text, Text>) : (InternalCandidTypes) {
        let candid_type : InternalCandidTypes = switch (candid) {
            case (#Nat(n)) (#Nat);
            case (#Nat8(n)) (#Nat8);
            case (#Nat16(n)) (#Nat16);
            case (#Nat32(n)) (#Nat32);
            case (#Nat64(n)) (#Nat64);

            case (#Int(n)) (#Int);
            case (#Int8(n)) (#Int8);
            case (#Int16(n)) (#Int16);
            case (#Int32(n)) (#Int32);
            case (#Int64(n)) (#Int64);

            case (#Float(n)) (#Float);

            case (#Bool(n)) (#Bool);

            case (#Principal(n)) (#Principal);

            case (#Text(n)) (#Text);

            case (#Null) (#Null);
            case (#Empty) (#Empty);

            case (#Blob(blob)) { #Array([#Nat8]) };

            case (#Option(optType)) {
                let inner_type = to_candid_types(optType, renaming_map);
                #Option(inner_type);
            };
            case (#Array(arr)) {
                let inner_types = Buffer.Buffer<InternalCandidTypes>(arr.size());

                for (item in arr.vals()) {
                    let (inner_type) = to_candid_types(item, renaming_map);
                    inner_types.add(inner_type);
                };

                let types = Buffer.toArray(inner_types);

                (#Array(types));
            };

            case (#Record(records) or #Map(records)) {
                let types_buffer = Buffer.Buffer<(Text, InternalCandidTypes)>(records.size());

                for ((record_key, record_val) in records.vals()) {
                    let (inner_type) = to_candid_types(record_val, renaming_map);

                    let renamed_key = get_renamed_key(renaming_map, record_key);

                    types_buffer.add((renamed_key, inner_type));
                };

                let types = Buffer.toArray(types_buffer);

                #Record(types);
            };

            case (#Variant((key, val))) {
                let (inner_type) = to_candid_types(val, renaming_map);
                let renamed_key = get_renamed_key(renaming_map, key);

                #Variant([(renamed_key, inner_type)]);
            };
        };

    };

    func generate_key_tag(key : Text) : Tag {
        if (Utils.isHash(key)) {
            let n = Utils.text_to_nat32(key);
            #hash(n);
        } else {
            #name(key);
        };
    };

    func internal_type_to_arg_type(internal_type : InternalType, vec_index : ?Nat) : Type {
        switch (internal_type, vec_index) {
            case (#vector(vec_types), ?vec_index) #vector(internal_type_to_arg_type(vec_types[vec_index], null));
            case (#vector(vec_types), _) #vector(internal_type_to_arg_type(vec_types[0], null));
            case (#opt(opt_type), _) #opt(internal_type_to_arg_type(opt_type, null));
            case (#record(record_types), _) {
                let new_record_types = Array.map<InternalKeyValuePair, RecordFieldType>(
                    record_types,
                    func({ type_; tag } : InternalKeyValuePair) : RecordFieldType = {
                        type_ = internal_type_to_arg_type(type_, null);
                        tag;
                    },
                );

                #record(new_record_types);
            };
            case (#variant(variant_types), _) {
                let new_variant_types = Array.map<InternalKeyValuePair, RecordFieldType>(
                    variant_types,
                    func({ type_; tag } : InternalKeyValuePair) : RecordFieldType = {
                        type_ = internal_type_to_arg_type(type_, null);
                        tag;
                    },
                );

                #variant(new_variant_types);
            };

            case (#reserved, _) #reserved;
            case (#null_, _) #null_;
            case (#empty, _) #empty;
            case (#bool, _) #bool;
            case (#principal, _) #principal;
            case (#text, _) #text;
            case (#nat, _) #nat;
            case (#nat8, _) #nat8;
            case (#nat16, _) #nat16;
            case (#nat32, _) #nat32;
            case (#nat64, _) #nat64;
            case (#int, _) #int;
            case (#int8, _) #int8;
            case (#int16, _) #int16;
            case (#int32, _) #int32;
            case (#int64, _) #int64;
            case (#float32, _) #float32;
            case (#float64, _) #float64;
        };
    };

    func internal_to_candid_type(internal_type : InternalCandidTypes, vec_index : ?Nat) : CandidType {
        switch (internal_type, vec_index) {
            case (#Array(vec_types), ?vec_index) #Array(internal_to_candid_type(vec_types[vec_index], null));
            case (#Array(vec_types), _) #Array(internal_to_candid_type(vec_types[0], null));
            case (#Option(opt_type), _) #Option(internal_to_candid_type(opt_type, null));
            case (#Record(record_types), _) {
                let new_record_types = Array.map<(Text, InternalCandidTypes), (Text, CandidType)>(
                    record_types,
                    func((key, field_type) : (Text, InternalCandidTypes)) : (Text, CandidType) {
                        let inner_type = internal_to_candid_type(field_type, null);
                        (key, inner_type);
                    },
                );

                #Record(new_record_types);
            };
            case (#Variant(variant_types), _) {
                let new_variant_types = Array.map<(Text, InternalCandidTypes), (Text, CandidType)>(
                    variant_types,
                    func((key, variant_type) : (Text, InternalCandidTypes)) : (Text, CandidType) {
                        let inner_type = internal_to_candid_type(variant_type, null);
                        (key, inner_type);
                    },
                );

                #Variant(new_variant_types);
            };
            case (#Recursive(n, inner_type), _) #Recursive(n);

            case (#Int, _) #Int;
            case (#Int8, _) #Int8;
            case (#Int16, _) #Int16;
            case (#Int32, _) #Int32;
            case (#Int64, _) #Int64;

            case (#Nat, _) #Nat;
            case (#Nat8, _) #Nat8;
            case (#Nat16, _) #Nat16;
            case (#Nat32, _) #Nat32;
            case (#Nat64, _) #Nat64;

            case (#Bool, _) #Bool;
            case (#Float, _) #Float;
            case (#Text, _) #Text;
            case (#Blob, _) #Blob;
            case (#Null, _) #Null;
            case (#Empty, _) #Empty;
            case (#Principal, _) #Principal;

        };
    };

    func to_record_field_type(node : TypeNode) : RecordFieldType = {
        type_ = node.type_;
        tag = node.tag;
    };

    func to_candid_record_field_type(node : CandidTypeNode) : (Text, CandidType) {
        let ?key = node.key else return Debug.trap("to_candid_record_field_type: key is null");
        return (key, node.type_);
    };

    func merge_variants_and_array_types(rows : Buffer<[InternalTypeNode]>) : Result<Type, Text> {
        let buffer = Buffer.Buffer<TypeNode>(8);

        func calc_height(parent : Nat, child : Nat) : Nat = parent + child;

        let ?_bottom = rows.removeLast() else return #err("trying to pop bottom but rows is empty");

        var bottom = Array.map(
            _bottom,
            func(node : InternalTypeNode) : TypeNode = {
                type_ = internal_type_to_arg_type(node.type_, null);
                height = node.height;
                parent_index = node.parent_index;
                tag = node.tag;
            },
        );

        while (rows.size() > 0) {

            let ?above_bottom = rows.removeLast() else return #err("trying to pop above_bottom but rows is empty");

            var bottom_iter = Itertools.peekable(bottom.vals());

            let variants = Buffer.Buffer<RecordFieldType>(bottom.size());
            let variant_indexes = Buffer.Buffer<Nat>(bottom.size());

            for ((index, parent_node) in Itertools.enumerate(above_bottom.vals())) {
                let tmp_bottom_iter = PeekableIter.takeWhile(bottom_iter, func({ parent_index; tag } : TypeNode) : Bool = index == parent_index);
                let { parent_index; tag = parent_tag } = parent_node;

                switch (parent_node.type_) {
                    case (#opt(_)) {
                        let ?child_node = tmp_bottom_iter.next() else return #err(" #opt error: no item in tmp_bottom_iter");

                        let merged_node : TypeNode = {
                            type_ = #opt(child_node.type_);
                            height = calc_height(parent_node.height, child_node.height);
                            parent_index;
                            tag = parent_tag;
                        };
                        buffer.add(merged_node);
                    };
                    case (#vector(_)) {
                        let vec_nodes = Iter.toArray(tmp_bottom_iter);

                        let max = {
                            var height = 0;
                            var type_ : Type = #empty;
                        };

                        for (node in vec_nodes.vals()) {
                            if (max.height < node.height) {
                                max.height := node.height;
                                max.type_ := node.type_;
                            };
                        };

                        let best_node : TypeNode = {
                            type_ = #vector(max.type_);
                            height = calc_height(parent_node.height, max.height);
                            parent_index;
                            tag = parent_tag;
                        };

                        buffer.add(best_node);
                    };
                    case (#record(_)) {
                        var height = 0;

                        func get_max_height(item : TypeNode) : TypeNode {
                            height := Nat.max(height, item.height);
                            item;
                        };

                        let composed_fn = Func.compose(to_record_field_type, get_max_height);

                        let record_type = Iter.toArray(
                            Iter.map(tmp_bottom_iter, composed_fn)
                        );

                        let merged_node : TypeNode = {
                            type_ = #record(record_type);
                            height = calc_height(parent_node.height, height);
                            parent_index;
                            tag = parent_tag;
                        };
                        buffer.add(merged_node);
                    };
                    case (#variant(_)) {
                        var height = 0;

                        func get_max_height(item : TypeNode) : TypeNode {
                            height := Nat.max(height, item.height);
                            item;
                        };

                        let composed_fn = Func.compose(to_record_field_type, get_max_height);

                        let variant_types = Iter.toArray(
                            Iter.map(tmp_bottom_iter, composed_fn)
                        );

                        for (variant_type in variant_types.vals()) {
                            variants.add(variant_type);
                        };

                        variant_indexes.add(buffer.size());

                        let merged_node : TypeNode = {
                            type_ = #variant(variant_types);
                            height = calc_height(parent_node.height, height);
                            parent_index;
                            tag = parent_tag;
                        };

                        buffer.add(merged_node);

                    };
                    case (_) {
                        let new_parent_node : TypeNode = {
                            type_ = internal_type_to_arg_type(parent_node.type_, null);
                            height = parent_node.height;
                            parent_index;
                            tag = parent_tag;
                        };

                        buffer.add(new_parent_node);
                    };
                };
            };

            if (variants.size() > 0) {
                let full_variant_type : Type = #variant(Buffer.toArray(variants));

                for (index in variant_indexes.vals()) {
                    let prev_node = buffer.get(index);
                    let new_node : TypeNode = {
                        type_ = full_variant_type;
                        height = prev_node.height;
                        parent_index = prev_node.parent_index;
                        tag = prev_node.tag;
                    };

                    buffer.put(index, new_node);
                };
            };

            bottom := Buffer.toArray(buffer);
            buffer.clear();
        };

        let merged_type = bottom[0].type_;
        #ok(merged_type);
    };

    func merge_candid_variants_and_array_types(rows : Buffer<[InternalCandidTypeNode]>) : Result<CandidType, Text> {
        let buffer = Buffer.Buffer<CandidTypeNode>(8);

        func calc_height(parent : Nat, child : Nat) : Nat = parent + child;

        let ?_bottom = rows.removeLast() else return #err("trying to pop bottom but rows is empty");

        var bottom = Array.map(
            _bottom,
            func(node : InternalCandidTypeNode) : CandidTypeNode = {
                type_ = internal_to_candid_type(node.type_, null);
                height = node.height;
                parent_index = node.parent_index;
                key = node.key;
            },
        );

        while (rows.size() > 0) {

            let ?above_bottom = rows.removeLast() else return #err("trying to pop above_bottom but rows is empty");

            var bottom_iter = Itertools.peekable(bottom.vals());

            let variants = Buffer.Buffer<(Text, CandidType)>(bottom.size());
            let variant_indexes = Buffer.Buffer<Nat>(bottom.size());

            for ((index, parent_node) in Itertools.enumerate(above_bottom.vals())) {
                let tmp_bottom_iter = PeekableIter.takeWhile(bottom_iter, func({ parent_index; key } : CandidTypeNode) : Bool = index == parent_index);
                let { parent_index; key = parent_key } = parent_node;

                switch (parent_node.type_) {
                    case (#Option(_)) {
                        let ?child_node = tmp_bottom_iter.next() else return #err(" #Option error: no item in tmp_bottom_iter");

                        let merged_node : CandidTypeNode = {
                            type_ = #Option(child_node.type_);
                            height = calc_height(parent_node.height, child_node.height);
                            parent_index;
                            key = parent_key;
                        };
                        buffer.add(merged_node);
                    };
                    case (#Array(_)) {
                        let vec_nodes = Iter.toArray(tmp_bottom_iter);

                        let max = {
                            var height = 0;
                            var type_ : CandidType = #Empty;
                        };

                        for (node in vec_nodes.vals()) {
                            if (max.height < node.height) {
                                max.height := node.height;
                                max.type_ := node.type_;
                            };
                        };

                        let best_node : CandidTypeNode = {
                            type_ = #Array(max.type_);
                            height = calc_height(parent_node.height, max.height);
                            parent_index;
                            key = parent_key;
                        };

                        buffer.add(best_node);
                    };
                    case (#Record(_)) {
                        var height = 0;

                        func get_max_height(item : CandidTypeNode) {
                            height := Nat.max(height, item.height);
                        };

                        let record_fields : [(Text, CandidType)] = Iter.toArray(
                            Iter.map<CandidTypeNode, (Text, CandidType)>(
                                tmp_bottom_iter,
                                func(node : CandidTypeNode) : (Text, CandidType) {
                                    get_max_height(node);
                                    to_candid_record_field_type(node);
                                },
                            )
                        );

                        let merged_node : CandidTypeNode = {
                            type_ = #Record(record_fields);
                            height = calc_height(parent_node.height, height);
                            parent_index;
                            key = parent_key;
                        };
                        buffer.add(merged_node);
                    };
                    case (#Variant(_)) {
                        var height = 0;

                        func get_max_height(item : CandidTypeNode) {
                            height := Nat.max(height, item.height);
                        };

                        let variant_types : [(Text, CandidType)] = Iter.toArray(
                            Iter.map<CandidTypeNode, (Text, CandidType)>(
                                tmp_bottom_iter,
                                func(node : CandidTypeNode) : (Text, CandidType) {
                                    get_max_height(node);
                                    to_candid_record_field_type(node);
                                },
                            )
                        );

                        for (variant_type in variant_types.vals()) {
                            variants.add(variant_type);
                        };

                        variant_indexes.add(buffer.size());

                        let merged_node : CandidTypeNode = {
                            type_ = #Variant(variant_types);
                            height = calc_height(parent_node.height, height);
                            parent_index;
                            key = parent_key;
                        };

                        buffer.add(merged_node);

                    };
                    case (_) {
                        let new_parent_node : CandidTypeNode = {
                            type_ = internal_to_candid_type(parent_node.type_, null);
                            height = parent_node.height;
                            parent_index;
                            key = parent_key;
                        };

                        buffer.add(new_parent_node);
                    };
                };
            };

            if (variants.size() > 0) {
                let full_variant_type : CandidType = #Variant(Buffer.toArray(variants));

                for (index in variant_indexes.vals()) {
                    let prev_node = buffer.get(index);
                    let new_node : CandidTypeNode = {
                        type_ = full_variant_type;
                        height = prev_node.height;
                        parent_index = prev_node.parent_index;
                        key = prev_node.key;
                    };

                    buffer.put(index, new_node);
                };
            };

            bottom := Buffer.toArray(buffer);
            buffer.clear();
        };

        let merged_type = bottom[0].type_;
        #ok(merged_type);
    };

    func get_height_value(type_ : InternalType) : Nat {
        switch (type_) {
            case (#empty or #null_) 0;
            case (_) 1;
        };
    };

    func get_candid_height_value(type_ : InternalCandidTypes) : Nat {
        switch (type_) {
            case (#Empty or #Null) 0;
            case (_) 1;
        };
    };

    func order_types_by_height_bfs(rows : Buffer<[InternalTypeNode]>) {

        label while_loop while (rows.size() > 0) {
            let candid_values = Buffer.last(rows) else return Prelude.unreachable();
            let buffer = Buffer.Buffer<InternalTypeNode>(8);

            var has_compound_type = false;

            for ((index, parent_node) in Itertools.enumerate(candid_values.vals())) {

                switch (parent_node.type_) {
                    case (#opt(opt_val)) {
                        has_compound_type := true;
                        let child_node : InternalTypeNode = {
                            type_ = opt_val;
                            height = get_height_value(opt_val);
                            parent_index = index;
                            tag = #name("");
                        };

                        buffer.add(child_node);
                    };
                    case (#vector(vec_types)) {
                        has_compound_type := true;

                        for (vec_type in vec_types.vals()) {
                            let child_node : InternalTypeNode = {
                                type_ = vec_type;
                                height = get_height_value(vec_type);
                                parent_index = index;
                                tag = #name("");
                            };

                            buffer.add(child_node);
                        };

                    };
                    case (#record(records)) {

                        for ({ tag; type_ } in records.vals()) {
                            has_compound_type := true;
                            let child_node : InternalTypeNode = {
                                type_ = type_;
                                height = get_height_value(type_);
                                parent_index = index;
                                tag;
                            };
                            buffer.add(child_node);
                        };
                    };
                    case (#variant(variants)) {
                        has_compound_type := true;

                        for ({ tag; type_ } in variants.vals()) {
                            has_compound_type := true;
                            let child_node : InternalTypeNode = {
                                type_ = type_;
                                height = get_height_value(type_);
                                parent_index = index;
                                tag;
                            };
                            buffer.add(child_node);
                        };
                    };
                    case (_) {};
                };
            };

            if (has_compound_type) {
                rows.add(Buffer.toArray(buffer));
            } else {
                return;
            };
        };
    };

    // for most of the typs we can easily retrieve it from the value, but for an array it becomes a bit tricky
    // because of optional values we can have seemingly different types in the array
    // for example type [?Nat] with values [null, ?1], for each values will have a inferred type of [#Option(#Null), #Option(#Nat)]
    // We need a way to choose #Option(#Nat) over #Option(#Null) in this case

    func order_candid_types_by_height_bfs(rows : Buffer<[InternalCandidTypeNode]>) {

        label while_loop while (rows.size() > 0) {
            let candid_values = Buffer.last(rows) else return Prelude.unreachable();
            let buffer = Buffer.Buffer<InternalCandidTypeNode>(8);

            var has_compound_type = false;

            for ((index, parent_node) in Itertools.enumerate(candid_values.vals())) {

                switch (parent_node.type_) {
                    case (#Option(inner_type)) {
                        has_compound_type := true;
                        let child_node : InternalCandidTypeNode = {
                            type_ = inner_type;
                            height = get_candid_height_value(inner_type);
                            parent_index = index;
                            key = null;
                        };

                        buffer.add(child_node);
                    };
                    case (#Array(vec_types)) {
                        has_compound_type := true;

                        for (vec_type in vec_types.vals()) {
                            let child_node : InternalCandidTypeNode = {
                                type_ = vec_type;
                                height = get_candid_height_value(vec_type);
                                parent_index = index;
                                key = null;
                            };

                            buffer.add(child_node);
                        };

                    };
                    case (#Record(records)) {

                        for ((key, field_type) in records.vals()) {
                            has_compound_type := true;
                            let child_node : InternalCandidTypeNode = {
                                type_ = field_type;
                                height = get_candid_height_value(field_type);
                                parent_index = index;
                                key = ?key;
                            };
                            buffer.add(child_node);
                        };
                    };
                    case (#Variant(variants)) {
                        has_compound_type := true;

                        for ((key, variant_type) in variants.vals()) {
                            has_compound_type := true;
                            let child_node : InternalCandidTypeNode = {
                                type_ = variant_type;
                                height = get_candid_height_value(variant_type);
                                parent_index = index;
                                key = ?key;
                            };
                            buffer.add(child_node);
                        };
                    };
                    case (_) {};
                };
            };

            if (has_compound_type) {
                rows.add(Buffer.toArray(buffer));
            } else {
                return;
            };
        };
    };

    func get_renamed_key(renaming_map : TrieMap<Text, Text>, key : Text) : Text {
        switch (renaming_map.get(key)) {
            case (?v) v;
            case (_) key;
        };
    };
};
