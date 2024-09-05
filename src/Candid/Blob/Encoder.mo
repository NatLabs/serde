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
import Option "mo:base/Option";
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
import CandidUtils "CandidUtils";

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
    type Iter<A> = Iter.Iter<A>;
    type Hash = Nat32;
    type Map<K, V> = Map.Map<K, V>;
    type Order = Order.Order;

    type Candid = T.Candid;
    type CandidType = T.CandidType;
    type KeyValuePair = T.KeyValuePair;
    let { n32hash; thash } = Map;
    let { unsigned_leb128; signed_leb128_64 } = Utils;

    public func encode(candid_values : [Candid], options : ?T.Options) : Result<Blob, Text> {
        one_shot(candid_values, options);
    };

    public func encodeOne(candid : Candid, options : ?T.Options) : Result<Blob, Text> {
        encode([candid], options);
    };

    func div_ceil(n : Nat, d : Nat) : Nat {
        (n + d - 1) / d;
    };

    func infer_candid_types(candid_values : [Candid], renaming_map : Map<Text, Text>) : Result<[CandidType], Text> {
        let buffer = Buffer.Buffer<CandidType>(candid_values.size());

        for (candid in candid_values.vals()) {
            let candid_type = to_candid_types(candid, renaming_map);

            let rows = Buffer.Buffer<[InternalCandidTypeNode]>(8);

            let node : InternalCandidTypeNode = {
                type_ = candid_type;
                height = 0;
                parent_index = 0;
                key = null;
            };

            rows.add([node]);

            order_candid_types_by_height_bfs(rows);

            let res = merge_candid_variants_and_array_types(rows);
            let #ok(merged_type) = res else return Utils.send_error(res);

            buffer.add(merged_type);
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

    public func one_shot(candid_values : [Candid], _options : ?T.Options) : Result<Blob, Text> {

        let renaming_map = Map.new<Text, Text>();

        let compound_type_buffer = Buffer.Buffer<Nat8>(200);
        let primitive_type_buffer = Buffer.Buffer<Nat8>(200);
        let value_buffer = Buffer.Buffer<Nat8>(200);

        let counter = [var 0];

        let options = Option.get(_options, T.defaultOptions);

        for ((k, v) in options.renameKeys.vals()) {
            ignore Map.put(renaming_map, thash, k, v);
        };

        var candid_types : [CandidType] = switch (options.types) {
            case (?types) { types };
            case (_) switch (infer_candid_types(candid_values, renaming_map)) {
                case (#ok(inferred_types)) inferred_types;
                case (#err(e)) return #err(e);
            };
        };

        // need to sort both inferred and provided types
        candid_types := Array.map(
            candid_types,
            func(candid_type : CandidType) : CandidType = CandidUtils.format_candid_type(candid_type, renaming_map),
        );

        one_shot_encode(
            candid_types,
            candid_values,
            compound_type_buffer,
            primitive_type_buffer,
            value_buffer,
            counter,
            renaming_map,
        );

        let candid_buffer = Buffer.fromArray<Nat8>([0x44, 0x49, 0x44, 0x4C]); // 'DIDL' magic bytes

        // add compound type to the buffer
        let compound_type_size_bytes = Buffer.Buffer<Nat8>(8);
        unsigned_leb128(compound_type_size_bytes, counter[C.COUNTER.COMPOUND_TYPE]);

        // add primitive type to the buffer
        let primitive_type_size_bytes = Buffer.Buffer<Nat8>(8);
        unsigned_leb128(primitive_type_size_bytes, candid_values.size());

        let total_size = candid_buffer.size() + compound_type_size_bytes.size() + compound_type_buffer.size() + primitive_type_size_bytes.size() + primitive_type_buffer.size() + value_buffer.size();

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
                    func(_ : Nat) : Nat8 {
                        var buffer = sequence[i];
                        while (j >= buffer.size()) {
                            j := 0;
                            i += 1;
                            buffer := sequence[i];
                        };

                        let byte = buffer.get(j);
                        j += 1;
                        byte;
                    },
                )
            )
        );
    };

    func check_is_tuple(candid_types : [(Text, Any)]) : Bool {
        let n = candid_types.size(); // 0-based index
        var sum_of_n : Int = (n * (n + 1)) / 2;

        var i = 0;
        label tuple_check while (i < candid_types.size()) {
            let record_key = candid_types[i].0;

            if (Utils.text_is_number(record_key)) {
                sum_of_n -= (Utils.text_to_nat(record_key) + 1);
            } else break tuple_check;

            i += 1;
        };

        sum_of_n == 0;
    };

    func tuple_type_to_record(tuple_types : [CandidType]) : [(Text, CandidType)] {
        Array.tabulate<(Text, CandidType)>(
            tuple_types.size(),
            func(i : Nat) : (Text, CandidType) {
                (debug_show (i), tuple_types[i]);
            },
        );
    };

    func tuple_value_to_record(tuple_values : [Candid]) : [(Text, Candid)] {
        Array.tabulate<(Text, Candid)>(
            tuple_values.size(),
            func(i : Nat) : (Text, Candid) {
                (debug_show i, tuple_values[i]);
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
        renaming_map : Map<Text, Text>,
    ) {
        assert candid_values.size() == candid_types.size();

        // include size of candid values
        // unsigned_leb128(type_buffer, candid_values.size());

        let unique_compound_type_map = Map.new<Text, Nat>();
        let recursive_map = Map.new<Text, Text>();

        var i = 0;

        while (i < candid_values.size()) {

            ignore encode_candid(
                candid_types[i],
                candid_values[i],
                compound_type_buffer,
                primitive_type_buffer,
                value_buffer,
                renaming_map,
                unique_compound_type_map,
                recursive_map,
                counter,
                false,
                false,
            );

            i += 1;
        };

    };

    func is_compound_type(candid_type : CandidType) : Bool {
        switch (candid_type) {
            case (#Option(_) or #Array(_) or #Record(_) or #Map(_) or #Tuple(_) or #Variant(_) or #Recursive(_) or #Blob(_)) true;
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
        renaming_map : Map<Text, Text>,
        unique_compound_type_map : Map<Text, Nat>,
        counter : [var Nat],
        is_nested_child_of_compound_type : Bool,
    ) {
        let type_info = debug_show candid_type;
        let compound_type_exists = Map.has(unique_compound_type_map, thash, type_info);
        if (compound_type_exists) return;
        // Debug.print("encode_compound_type_only(): " # debug_show type_info);
        switch (candid_type) {
            case (#Option(opt_type)) {
                let opt_type_is_compound = is_compound_type(opt_type);

                if (not opt_type_is_compound) {
                    compound_type_buffer.add(T.TypeCode.Option);
                };

                encode_type_only(
                    opt_type,
                    compound_type_buffer,
                    primitive_type_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    counter,
                    true,
                );

                if (opt_type_is_compound) {
                    compound_type_buffer.add(T.TypeCode.Option);
                    let opt_type_info = debug_show opt_type;
                    let pos = switch (Map.get(unique_compound_type_map, thash, opt_type_info)) {
                        case (?pos) pos;
                        case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info));
                    };
                    unsigned_leb128(compound_type_buffer, pos);
                };

            };

            case (#Array(arr_type)) {
                let arr_type_is_compound = is_compound_type(arr_type);
                if (not arr_type_is_compound) {
                    compound_type_buffer.add(T.TypeCode.Array);
                };

                encode_type_only(
                    arr_type,
                    compound_type_buffer,
                    primitive_type_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    counter,
                    true,
                );

                if (arr_type_is_compound) {
                    compound_type_buffer.add(T.TypeCode.Array);
                    let arr_type_info = debug_show arr_type;
                    let pos = switch (Map.get(unique_compound_type_map, thash, arr_type_info)) {
                        case (?pos) pos;
                        case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info));
                    };
                    unsigned_leb128(compound_type_buffer, pos);
                };
            };

            case (#Blob) return encode_compound_type_only(
                #Array(#Nat8),
                compound_type_buffer,
                primitive_type_buffer,
                renaming_map,
                unique_compound_type_map,
                counter,
                true,
            );

            case (#Record(record_types) or #Map(record_types)) {
                let is_tuple = check_is_tuple(record_types);

                var i = 0;
                while (i < record_types.size()) {
                    let value_type = record_types[i].1;

                    let value_type_is_compound = is_compound_type(value_type);

                    if (value_type_is_compound) encode_type_only(
                        value_type,
                        compound_type_buffer,
                        primitive_type_buffer,
                        renaming_map,
                        unique_compound_type_map,
                        counter,
                        true,
                    );

                    i += 1;
                };

                compound_type_buffer.add(T.TypeCode.Record);
                unsigned_leb128(compound_type_buffer, record_types.size());

                i := 0;
                while (i < record_types.size()) {
                    let value_type = record_types[i].1;

                    let value_type_is_compound = is_compound_type(value_type);

                    if (is_tuple) {
                        unsigned_leb128(compound_type_buffer, i);
                    } else {
                        let record_key = get_renamed_key(renaming_map, record_types[i].0);

                        let hash_key = hash_record_key(record_key);
                        unsigned_leb128(compound_type_buffer, Nat32.toNat(hash_key));
                    };

                    if (value_type_is_compound) {
                        let value_type_info = debug_show value_type;
                        let pos = switch (Map.get(unique_compound_type_map, thash, value_type_info)) {
                            case (?pos) pos;
                            case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info));
                        };
                        unsigned_leb128(compound_type_buffer, pos);
                    } else {
                        encode_primitive_type_only(
                            value_type,
                            compound_type_buffer,
                            primitive_type_buffer,
                            true,
                        );
                    };

                    i += 1;
                };
            };

            case (#Tuple(tuple_types)) {
                return encode_compound_type_only(
                    #Record(tuple_type_to_record(tuple_types)),
                    compound_type_buffer,
                    primitive_type_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    counter,
                    true,
                );
            };

            case (#Variant(variant_types)) {

                var i = 0;
                while (i < variant_types.size()) {
                    let variant_type = variant_types[i].1;

                    let variant_type_is_compound = is_compound_type(variant_type);

                    if (variant_type_is_compound) {
                        encode_compound_type_only(
                            variant_type,
                            compound_type_buffer,
                            primitive_type_buffer,
                            renaming_map,
                            unique_compound_type_map,
                            counter,
                            true,
                        );
                    };

                    i += 1;
                };

                compound_type_buffer.add(T.TypeCode.Variant);
                unsigned_leb128(compound_type_buffer, variant_types.size());

                i := 0;
                while (i < variant_types.size()) {
                    let variant_key = get_renamed_key(renaming_map, variant_types[i].0);
                    let variant_type = variant_types[i].1;
                    let variant_type_is_compound = is_compound_type(variant_type);

                    let hash_key = hash_record_key(variant_key);
                    unsigned_leb128(compound_type_buffer, Nat32.toNat(hash_key));

                    if (variant_type_is_compound) {
                        let variant_type_info = debug_show variant_type;
                        let pos = switch (Map.get(unique_compound_type_map, thash, variant_type_info)) {
                            case (?pos) pos;
                            case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info));
                        };
                        unsigned_leb128(compound_type_buffer, pos);
                    } else {
                        encode_primitive_type_only(
                            variant_type,
                            compound_type_buffer,
                            primitive_type_buffer,
                            true,
                        );
                    };

                    i += 1;
                };
            };

            case (_) Debug.trap("encode_compound_type_only(): unknown compound type " # debug_show candid_type);
        };

        ignore Map.put(unique_compound_type_map, thash, type_info, counter[C.COUNTER.COMPOUND_TYPE]);
        counter[C.COUNTER.COMPOUND_TYPE] += 1;

    };

    func encode_type_only(
        candid_type : CandidType,
        compound_type_buffer : Buffer<Nat8>,
        primitive_type_buffer : Buffer<Nat8>,
        renaming_map : Map<Text, Text>,
        unique_compound_type_map : Map<Text, Nat>,
        counter : [var Nat],
        is_nested_child_of_compound_type : Bool,
    ) {
        if (is_compound_type(candid_type)) {
            encode_compound_type_only(
                candid_type,
                compound_type_buffer,
                primitive_type_buffer,
                renaming_map,
                unique_compound_type_map,
                counter,
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
    func get_type_info(_candid_type : CandidType) : Text {
        let candid_type = switch (_candid_type) {
            case (#Map(records)) #Record(records);
            case (#Blob) #Array(#Nat8);
            case (#Tuple(tuple_types)) #Record(tuple_type_to_record(tuple_types));
            case (candid_type) candid_type;
        };

        debug_show candid_type;
    };

    func encode_primitive_type(
        candid_type : CandidType,
        candid_value : Candid,
        compound_type_buffer : Buffer<Nat8>,
        primitive_type_buffer : Buffer<Nat8>,
        value_buffer : Buffer<Nat8>,
        renaming_map : Map<Text, Text>,
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
                unsigned_leb128(value_buffer, n);

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
                unsigned_leb128(value_buffer, utf8_bytes.size());

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
                unsigned_leb128(value_buffer, bytes.size());

                var i = 0;
                while (i < bytes.size()) {
                    value_buffer.add(bytes[i]);
                    i += 1;
                };
            };

            case (_) Debug.trap("unknown (type, value) pair: " # debug_show (candid_type, candid_value));
        };
    };

    func encode_compound_type(
        candid_type : CandidType,
        candid_value : Candid,
        compound_type_buffer : Buffer<Nat8>,
        primitive_type_buffer : Buffer<Nat8>,
        value_buffer : Buffer<Nat8>,
        renaming_map : Map<Text, Text>,
        unique_compound_type_map : Map<Text, Nat>,
        recursive_map : Map<Text, Text>,
        counter : [var Nat],
        is_nested_child_of_compound_type : Bool,
        _type_exists : Bool,
    ) {

        // Debug.print("encode_compound_type(): " # debug_show (candid_type, candid_value));

        // ----------------- Compound Types ----------------- //

        // encode_candid type only
        // case (candid_type, #Null) {
        //     encode_nested_type(candid_type, compound_type_buffer);
        // };

        let type_info = get_type_info(candid_type);

        // type_exists_in_compound_type_sequence
        let type_exists = _type_exists or Map.has(unique_compound_type_map, thash, type_info);

        switch (candid_type, candid_value) {

            case (#Option(opt_type), #Option(opt_value)) {

                let opt_type_is_compound = is_compound_type(opt_type);

                if (not type_exists and not opt_type_is_compound) {
                    compound_type_buffer.add(T.TypeCode.Option);
                };

                if (opt_value == #Null and opt_type != #Null) {
                    // a result of being able to set #Null at any point in an #Option type
                    // for instance, type #Option(#Nat) with value #Null

                    value_buffer.add(0); // no value

                    if (not type_exists) encode_type_only(
                        opt_type,
                        compound_type_buffer,
                        primitive_type_buffer,
                        renaming_map,
                        unique_compound_type_map,
                        counter,
                        true,
                    );

                } else {
                    value_buffer.add(1); // has value

                    ignore encode_candid(
                        opt_type,
                        opt_value,
                        compound_type_buffer,
                        primitive_type_buffer,
                        value_buffer,
                        renaming_map,
                        unique_compound_type_map,
                        recursive_map,
                        counter,
                        true,
                        type_exists,
                    );
                };

                if (
                    not type_exists and opt_type_is_compound
                ) {
                    // let prev_start = get_prev_compound_type_start_index(compound_type_buffer);
                    compound_type_buffer.add(T.TypeCode.Option);
                    let opt_type_info = get_type_info(opt_type);
                    let pos = switch (Map.get(unique_compound_type_map, thash, opt_type_info)) {
                        case (?pos) pos;
                        case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info));
                    };
                    unsigned_leb128(compound_type_buffer, pos);
                };
            };

            // a result of being able to set #Null at any point in an #Option type
            // for instance, type #Option(#Nat) with value #Null
            case (#Option(opt_type), #Null) {
                value_buffer.add(0); // no value

                let opt_type_is_compound = is_compound_type(opt_type);

                if (not type_exists and not opt_type_is_compound) {
                    compound_type_buffer.add(T.TypeCode.Option);
                };

                if (not type_exists) encode_type_only(
                    opt_type,
                    compound_type_buffer,
                    primitive_type_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    counter,
                    true,
                );

                if (
                    not type_exists and opt_type_is_compound
                ) {
                    compound_type_buffer.add(T.TypeCode.Option);
                    let opt_type_info = get_type_info(opt_type);
                    let pos = switch (Map.get(unique_compound_type_map, thash, opt_type_info)) {
                        case (?pos) pos;
                        case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info, opt_type));
                    };
                    unsigned_leb128(compound_type_buffer, pos);
                };

            };

            case (#Array(arr_type), #Array(arr_values)) {
                let arr_type_is_compound = is_compound_type(arr_type);

                if (not type_exists and not arr_type_is_compound) {
                    compound_type_buffer.add(T.TypeCode.Array);
                };

                // if (not type_exists)

                unsigned_leb128(value_buffer, arr_values.size());

                var i = 0;

                if (arr_values.size() == 0 and not type_exists) {
                    encode_type_only(
                        arr_type,
                        compound_type_buffer,
                        primitive_type_buffer,
                        renaming_map,
                        unique_compound_type_map,
                        counter,
                        true,
                    );
                } else while (i < arr_values.size()) {
                    let val = arr_values[i];

                    ignore encode_candid(
                        arr_type,
                        val,
                        compound_type_buffer,
                        primitive_type_buffer,
                        value_buffer,
                        renaming_map,
                        unique_compound_type_map,
                        recursive_map,
                        counter,
                        true,
                        type_exists or i > 0,
                    );

                    i += 1;
                };

                if (not type_exists and arr_type_is_compound) {
                    compound_type_buffer.add(T.TypeCode.Array);

                    let arr_type_info = get_type_info(arr_type);
                    let pos = switch (Map.get(unique_compound_type_map, thash, arr_type_info)) {
                        case (?pos) pos;
                        case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info, arr_type));
                    };
                    unsigned_leb128(compound_type_buffer, pos);

                };

            };
            case (#Blob, #Blob(blob)) {
                let bytes = Array.map(Blob.toArray(blob), func(n : Nat8) : Candid = #Nat8(n));

                return encode_compound_type(
                    #Array(#Nat8),
                    #Array(bytes),
                    compound_type_buffer,
                    primitive_type_buffer,
                    value_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    recursive_map,
                    counter,
                    is_nested_child_of_compound_type,
                    type_exists,
                );
            };

            case (#Array(#Nat8), #Blob(blob)) {
                let bytes = Array.map(Blob.toArray(blob), func(n : Nat8) : Candid = #Nat8(n));

                return encode_compound_type(
                    #Array(#Nat8),
                    #Array(bytes),
                    compound_type_buffer,
                    primitive_type_buffer,
                    value_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    recursive_map,
                    counter,
                    is_nested_child_of_compound_type,
                    type_exists,
                );
            };
            case (#Blob, #Array(bytes)) {
                if (bytes.size() > 0) {
                    switch (bytes[0]) {
                        case (#Nat8(_)) {};
                        case (_) return Debug.trap("invalid blob value: expected array of Nat8, got array of " # debug_show bytes[0]);
                    };
                };

                return encode_compound_type(
                    #Array(#Nat8),
                    #Array(bytes),
                    compound_type_buffer,
                    primitive_type_buffer,
                    value_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    recursive_map,
                    counter,
                    is_nested_child_of_compound_type,
                    type_exists,
                );
            };

            case (#Record(record_types) or #Map(record_types), #Record(record_entries) or #Map(record_entries)) {
                assert record_entries.size() == record_types.size();

                let is_tuple = check_is_tuple(record_types);

                let sorted_record_entries = Array.tabulate<(Text, Candid)>(
                    record_types.size(),
                    func(i : Nat) : (Text, Candid) {
                        let field_type_key = get_renamed_key(renaming_map, record_types[i].0);
                        let res = Array.find<(Text, Candid)>(
                            record_entries,
                            func((field_value_key, _) : (Text, Candid)) : Bool {
                                get_renamed_key(renaming_map, field_value_key) == field_type_key;
                            },
                        );

                        switch (res) {
                            case (?(_, field_value)) (field_type_key, field_value);
                            case (_) Debug.trap("unable to find field key in field types: " # debug_show field_type_key # "in " # debug_show record_entries);
                        };
                    },
                );

                var i = 0;
                while (i < record_types.size()) {
                    let value_type = record_types[i].1;
                    let field_value = sorted_record_entries[i].1;

                    let value_type_is_compound = is_compound_type(value_type);

                    ignore encode_candid(
                        value_type,
                        field_value,
                        compound_type_buffer,
                        primitive_type_buffer,
                        value_buffer,
                        renaming_map,
                        unique_compound_type_map,
                        recursive_map,
                        counter,
                        true,
                        type_exists or not value_type_is_compound,
                    );

                    i += 1;
                };

                if (not type_exists) {
                    compound_type_buffer.add(T.TypeCode.Record);
                    unsigned_leb128(compound_type_buffer, record_entries.size());

                    i := 0;

                    while (i < record_types.size()) {
                        let value_type = record_types[i].1;

                        let value_type_is_compound = is_compound_type(value_type);

                        if (is_tuple) {
                            unsigned_leb128(compound_type_buffer, i);
                        } else {
                            let record_key = get_renamed_key(renaming_map, record_types[i].0);
                            let hash_key = hash_record_key(record_key);
                            unsigned_leb128(compound_type_buffer, Nat32.toNat(hash_key));
                        };

                        if (value_type_is_compound) {
                            let value_type_info = get_type_info(value_type);
                            let pos = switch (Map.get(unique_compound_type_map, thash, value_type_info)) {
                                case (?pos) pos;
                                case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info, value_type));
                            };

                            unsigned_leb128(compound_type_buffer, pos);
                        } else {
                            encode_primitive_type_only(
                                value_type,
                                compound_type_buffer,
                                primitive_type_buffer,
                                true,
                            );
                        };

                        i += 1;
                    };
                };

            };
            case (#Tuple(tuple_types), #Tuple(tuple_values)) {
                return encode_compound_type(
                    #Record(tuple_type_to_record(tuple_types)),
                    #Record(tuple_value_to_record(tuple_values)),
                    compound_type_buffer,
                    primitive_type_buffer,
                    value_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    recursive_map,
                    counter,
                    is_nested_child_of_compound_type,
                    type_exists,
                );
            };
            case (#Tuple(tuple_types), #Record(tuple_values)) {
                var i = 0;
                assert Itertools.all(
                    tuple_values.vals(),
                    func((k, v) : (Text, Any)) : Bool {
                        i += 1;
                        Utils.text_is_number(k) and Utils.text_to_nat(k) == (i - 1);
                    },
                );

                return encode_compound_type(
                    #Record(tuple_type_to_record(tuple_types)),
                    #Record(tuple_values),
                    compound_type_buffer,
                    primitive_type_buffer,
                    value_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    recursive_map,
                    counter,
                    is_nested_child_of_compound_type,
                    type_exists,
                );
            };

            case (#Record(record_types), #Tuple(tuple_values)) {
                var i = 0;
                assert Itertools.all(
                    record_types.vals(),
                    func((k, v) : (Text, Any)) : Bool {
                        i += 1;
                        Utils.text_is_number(k) and Utils.text_to_nat(k) == (i - 1);
                    },
                );

                return encode_compound_type(
                    #Record(record_types),
                    #Record(tuple_value_to_record(tuple_values)),
                    compound_type_buffer,
                    primitive_type_buffer,
                    value_buffer,
                    renaming_map,
                    unique_compound_type_map,
                    recursive_map,
                    counter,
                    is_nested_child_of_compound_type,
                    type_exists,
                );
            };

            case (#Variant(variant_types), #Variant(variant)) {
                let variant_key = get_renamed_key(renaming_map, variant.0);
                let variant_value = variant.1;

                let variant_index_res = Array.indexOf<(Text, CandidType)>(
                    (variant_key, #Empty), // attach #Empty variant type to satisfy the type checker
                    variant_types,
                    func((a, _) : (Text, CandidType), (b, _) : (Text, CandidType)) : Bool = a == b,
                );

                let variant_index = switch (variant_index_res) {
                    case (?index) index;
                    case (_) Debug.trap("unable to find variant key in variant types");
                };

                var i = 0;
                while (i < variant_types.size()) {
                    let variant_key = variant_types[i].0;
                    let variant_type = variant_types[i].1;

                    let variant_type_is_compound = is_compound_type(variant_type);

                    if (i == variant_index) {
                        unsigned_leb128(value_buffer, i);

                        ignore encode_candid(
                            variant_type,
                            variant_value,
                            compound_type_buffer,
                            primitive_type_buffer,
                            value_buffer,
                            renaming_map,
                            unique_compound_type_map,
                            recursive_map,
                            counter,
                            true,
                            type_exists or not variant_type_is_compound,
                        );
                    } else if (variant_type_is_compound) {
                        encode_compound_type_only(
                            variant_type,
                            compound_type_buffer,
                            primitive_type_buffer,
                            renaming_map,
                            unique_compound_type_map,
                            counter,
                            true,
                        );
                    };

                    i += 1;
                };

                if (not type_exists) {
                    compound_type_buffer.add(T.TypeCode.Variant);
                    unsigned_leb128(compound_type_buffer, variant_types.size());

                    i := 0;
                    while (i < variant_types.size()) {
                        let variant_key = get_renamed_key(renaming_map, variant_types[i].0);
                        let variant_type = variant_types[i].1;
                        let variant_type_is_compound = is_compound_type(variant_type);

                        let hash_key = hash_record_key(variant_key);
                        unsigned_leb128(compound_type_buffer, Nat32.toNat(hash_key));

                        if (variant_type_is_compound) {
                            let variant_type_info = get_type_info(variant_type);
                            let pos = switch (Map.get(unique_compound_type_map, thash, variant_type_info)) {
                                case (?pos) pos;
                                case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info));
                            };
                            unsigned_leb128(compound_type_buffer, pos);
                        } else {
                            encode_primitive_type_only(
                                variant_type,
                                compound_type_buffer,
                                primitive_type_buffer,
                                true,
                            );
                        };

                        i += 1;
                    };
                };

            };

            case (_) Debug.trap("invalid (type, value) pair: " # debug_show { candid_type; candid_value });
        };

        if (not type_exists) {
            var pos = counter[C.COUNTER.COMPOUND_TYPE];
            counter[C.COUNTER.COMPOUND_TYPE] += 1;

            ignore Map.put(unique_compound_type_map, thash, type_info, pos);
        };

        // if it is the top level parent and not one of the nested children
        if (not is_nested_child_of_compound_type) {
            let pos = switch (Map.get(unique_compound_type_map, thash, type_info)) {
                case (?pos) pos;
                case (_) Debug.trap("unable to find compound type pos to store in primitive type sequence for " # debug_show (type_info));
            };
            unsigned_leb128(primitive_type_buffer, pos);
        };
    };

    func encode_candid(
        candid_type : CandidType,
        candid_value : Candid,
        compound_type_buffer : Buffer<Nat8>,
        primitive_type_buffer : Buffer<Nat8>,
        value_buffer : Buffer<Nat8>,
        renaming_map : Map<Text, Text>,
        unique_compound_type_map : Map<Text, Nat>,
        recursive_map : Map<Text, Text>,
        counter : [var Nat],
        is_nested_child_of_compound_type : Bool,
        ignore_type : Bool,
    ) : ?Hash {

        let candid_is_compound_type = is_compound_type(candid_type);

        if (candid_is_compound_type) {
            encode_compound_type(
                candid_type,
                candid_value,
                compound_type_buffer,
                primitive_type_buffer,
                value_buffer,
                renaming_map,
                unique_compound_type_map,
                recursive_map,
                counter,
                is_nested_child_of_compound_type,
                ignore_type,
            );
        } else {
            encode_primitive_type(
                candid_type,
                candid_value,
                compound_type_buffer,
                primitive_type_buffer,
                value_buffer,
                renaming_map,
                unique_compound_type_map,
                recursive_map,
                is_nested_child_of_compound_type,
                ignore_type,
            );
        };

        null;
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
        // #Map : [(Text, InternalCandidTypes)];
        #Tuple : [InternalCandidTypes];
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

    func to_candid_types(candid : Candid, renaming_map : Map<Text, Text>) : (InternalCandidTypes) {
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

                    types_buffer.add((record_key, inner_type));
                };

                let types = Buffer.toArray(types_buffer);

                #Record(types);
            };

            case (#Tuple(tuple_values)) {
                let tuple_types = Array.map(
                    tuple_values,
                    func(c : Candid) : InternalCandidTypes {
                        to_candid_types(c, renaming_map);
                    },
                );

                #Tuple(tuple_types);
            };

            case (#Variant((key, val))) {
                let (inner_type) = to_candid_types(val, renaming_map);

                #Variant([(key, inner_type)]);
            };
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
            case (#Tuple(tuple_types), _) {
                let new_tuple_types = Array.map<InternalCandidTypes, CandidType>(
                    tuple_types,
                    func(inner_type : InternalCandidTypes) : CandidType {
                        internal_to_candid_type(inner_type, null);
                    },
                );

                #Tuple(new_tuple_types);
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
            case (#Recursive(n, _), _) #Recursive(n);

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

    func to_candid_record_field_type(node : CandidTypeNode) : (Text, CandidType) {
        let ?key = node.key else return Debug.trap("to_candid_record_field_type: key is null");
        return (key, node.type_);
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

                        var record_fields : [(Text, CandidType)] = Iter.toArray(
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

                        var variant_types : [(Text, CandidType)] = Iter.toArray(
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

    func get_candid_height_value(type_ : InternalCandidTypes) : Nat {
        switch (type_) {
            case (#Empty or #Null) 0;
            case (_) 1;
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

    func get_renamed_key(renaming_map : Map<Text, Text>, key : Text) : Text {
        switch (Map.get(renaming_map, thash, key)) {
            case (?v) v;
            case (_) key;
        };
    };
};
