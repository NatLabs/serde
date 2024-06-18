import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Int64 "mo:base/Int64";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";

import Encoder "mo:candid/Encoder";
import Arg "mo:candid/Arg";
import Value "mo:candid/Value";
import Type "mo:candid/Type";
import Tag "mo:candid/Tag";
import Itertools "mo:itertools/Iter";
import PeekableIter "mo:itertools/PeekableIter";
import Map "mo:map/Map";

import T "../Types";
import TrieMap "mo:base/TrieMap";
import Utils "../../Utils";
import Func "mo:base/Func";
import Char "mo:base/Char";
import Int16 "mo:base/Int16";

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

    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;
    let { n32hash; thash } = Map;

    public func encode(candid_values : [Candid], options : ?T.Options) : Result<Blob, Text> {
        Debug.print("candid_values: " # debug_show candid_values);
        let renaming_map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        Debug.print("init renaming_map: ");
        ignore do ? {
            let renameKeys = options!.renameKeys;
            for ((k, v) in renameKeys.vals()) {
                renaming_map.put(k, v);
            };
        };

        Debug.print("filling renaming map");

        let res = toArgs(candid_values, renaming_map);
        Debug.print("converted to arge");

        let #ok(args) = res else return Utils.send_error(res);
        Debug.print("extract args from results");

        Debug.print(debug_show args);
        #ok(Encoder.encode(args));
    };

    public func encodeOne(candid : Candid, options : ?T.Options) : Result<Blob, Text> {
        encode([candid], options);
    };

    type CandidTypes = Candid.CandidTypes;

    func div_ceil(n : Nat, d : Nat) : Nat {
        (n + d - 1) / d;
    };

    // https://en.wikipedia.org/wiki/LEB128
    func unsigned_leb128(buffer : Buffer<Nat8>, n : Nat) {
        var n64 : Nat64 = Nat64.fromNat(n);
        let bit_length = Nat64.toNat(64 - Nat64.bitcountLeadingZero(n64));
        let n7bits = div_ceil(bit_length, 7);

        var i = 0;
        while (i < n7bits) {
            var byte = n64 & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
            n64 := n64 >> 7;

            byte := if (i == bits_of_7 - 1) (byte) else (byte | 0x80);
            buffer.add(byte);
            i += 1;
        };
    };

    func signed_leb128(buffer : Buffer<Nat8>, num : Int) {
        var i64 = if (num < 0) Int64.fromInt(-num) else return unsigned_leb128(buffer, Int.abs(num));

        let bit_length = Int64.toInt(64 - Int64.bitcountLeadingZero(i64)) |> Int.abs(_);
        let n7bits = div_ceil(bit_length, 7);

        // potentially replace with Int64.toNat64()
        let expected_bytes = (n7bits * 7);
        i64 := i64 ^ (0x7FFF_FFFF_FFFF_FFFF >> Int64.fromInt(63 - expected_bytes)); // flip all bits
        i64 += 1;

        var n64 = Int64.toInt(i64) |> Int.abs(_) |> Nat64.fromNat(_);

        var i = 0;

        while (i < n7bits) {
            var byte = n64 & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
            n64 := n64 >> 7;

            byte := if (i == n7bits - 1) (byte) else (byte | 0x80);
            buffer.add(byte);
            i += 1;
        };
    };

    public func one_shot(candid_values : [Candid], options : ?T.Options) : Result<Blob, Text> {
        Debug.print("candid_values: " # debug_show candid_values);
        let renaming_map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        let type_buffer = Buffer.Buffer(8);
        let value_buffer = Buffer.Buffer(8);

        Debug.print("init renaming_map: ");
        ignore do ? {
            let renameKeys = options!.renameKeys;
            for ((k, v) in renameKeys.vals()) {
                renaming_map.put(k, v);
            };
        };

        let buffer = one_shot_encode(candid_values, renaming_map);

        let type_blob = Blob.fromArray(Buffer.toArray(type_buffer));
        let value_blob = Blob.fromArray(Buffer.toArray(value_buffer));

        #ok(blob);
    };

    public func one_shot_encode(candid_types : [CandidTypes], candid_values : [Candid], type_buffer : Buffer<Nat8>, value_buffer : Buffer<Nat8>, renaming_map : TrieMap<Text, Text>) : Buffer<Nat8> {
        assert candid_values.size() == candid_types.size();

        // include size of candid values
        unsigned_leb128(type_buffer, candid_values.size());

        let unique_map = Map.new<Hash, Nat>();
        let recursive_map = Map.new<Text, Text>();
        let primitive_type_buffer = Buffer.Buffer<Nat8>(candid_values.size() * 8);

        func encode(
            candid_type : CandidTypes,
            candid_value : Candid,
            type_buffer : Buffer<Nat8>,
            primitive_type_buffer : Buffer<Nat8>,
            value_buffer : Buffer<Nat8>,
            renaming_map : TrieMap<Text, Text>,
            unique_map : Map<Hash, Nat>,
            recursive_map : Map<Text, Text>,
        ) : ?Hash {
            switch (candid_type, candid_value) {
                case (#Nat, #Nat(n)) {
                    primitive_type_buffer.add(T.TypeCode.Nat);
                    unsigned_leb128(value_buffer, n);
                    null;
                };
                case (#Nat8, #Nat8(n)) {
                    primitive_type_buffer.add(T.TypeCode.Nat8);
                    value_buffer.add(n);
                    null;
                };
                case (#Nat16, #Nat16(n)) {
                    primitive_type_buffer.add(T.TypeCode.Nat16);
                    value_buffer.add((n & 0xFF) |> Nat16.toNat8(_));
                    value_buffer.add((n >> 8) |> Nat16.toNat8(_));
                    null;
                };
                case (#Nat32, #Nat32(n)) {
                    primitive_type_buffer.add(T.TypeCode.Nat32);
                    value_buffer.add((n & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add(((n >> 8) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add(((n >> 16) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add((n >> 24) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    null;
                };
                case (#Nat64, #Nat64(n)) {
                    primitive_type_buffer.add(T.TypeCode.Nat64);
                    value_buffer.add((n & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 8) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 16) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 24) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 32) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 40) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 48) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add((n >> 56) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    null;
                };
                case (#Int, #Int(n)) {
                    primitive_type_buffer.add(T.TypeCode.Int);
                    signed_leb128(value_buffer, n);
                    null;
                };
                case (#Int8, #Int8(i8)) {
                    primitive_type_buffer.add(T.TypeCode.Int8);
                    value_buffer.add(Int8.toNat8(i8));
                    null;
                };
                case (#Int16, #Int16(i16)) {
                    primitive_type_buffer.add(T.TypeCode.Int16);
                    let n16 = Int16.toNat16(i16);
                    value_buffer.add((n16 & 0xFF) |> Nat16.toNat8(_));
                    value_buffer.add((n16 >> 8) |> Nat16.toNat8(_));
                    null;
                };
                case (#Int32, #Int32(i32)) {
                    primitive_type_buffer.add(T.TypeCode.Int32);
                    let n = Int32.toNat32(i32);

                    value_buffer.add((n & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add(((n >> 8) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add(((n >> 16) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    value_buffer.add((n >> 24) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                    null;
                };
                case (#Int64, #Int64(i64)) {
                    primitive_type_buffer.add(T.TypeCode.Int64);
                    let n = Int64.toNat64(i64);

                    value_buffer.add((n & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 8) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 16) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 24) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 32) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 40) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add(((n >> 48) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    value_buffer.add((n >> 56) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                    null;
                };
                case (#Float, #Float(f64)) {
                    Debug.trap("Float not implemented");
                    // primitive_type_buffer.add(T.TypeCode.Float);
                    // let bytes = Float.toBytes(f64);
                    // for (byte in bytes.vals()){
                    //     value_buffer.add(byte);
                    // };
                };
                case (#Bool, #Bool(b)) {
                    primitive_type_buffer.add(T.TypeCode.Bool);
                    value_buffer.add(if (b) (1) else (0));
                };
                case (#Null, #Null) {
                    primitive_type_buffer.add(T.TypeCode.Null);
                };
                case (#Empty, #Empty) {
                    primitive_type_buffer.add(T.TypeCode.Empty);
                };
                case (#Text, #Text(t)) {
                    primitive_type_buffer.add(T.TypeCode.Text);

                    let utf8_bytes = Blob.toArray(Text.encodeUtf8(t));
                    unsigned_leb128(value_buffer, utf8_bytes.size());

                    var i = 0;
                    while (i < utf8_bytes.size()) {
                        value_buffer.add(utf8_bytes[i]);
                        i += 1;
                    };

                };
                case (#Principal, #Principal(p)) {
                    primitive_type_buffer.add(T.TypeCode.Principal);

                    value_buffer.add(0x01); // indicate transparency state
                    let bytes = Blob.toArray(Principal.toBlob(p));
                    unsigned_leb128(value_buffer, bytes.size());

                    var i = 0;
                    while (i < bytes.size()) {
                        value_buffer.add(bytes[i]);
                        i += 1;
                    };
                };

                // ----------------- Compound Types ----------------- //

                case (#Option(opt_type), #Option(opt_value)) {
                    primitive_type_buffer.add(T.TypeCode.Option);
                    var checkpoint = value_buffer.size();

                    let hash = switch (opt_type, opt_value) {
                        case (_, #Null) {
                            value_buffer.add(0); // no value
                            let hash = hash_type(opt_type);
                        };
                        case (_, _) {
                            value_buffer.add(1); // has value
                            let hash = encode(
                                opt_type,
                                opt_value,
                                type_buffer,
                                primitive_type_buffer,
                                value_buffer,
                                renaming_map,
                                unique_map,
                                recursive_map,
                            );
                        };
                    };

                    if (hash == null) return null;

                    let ?offset = Map.get(unique_map, n32hash, hash) else return null;

                    unsigned_leb128(value_buffer, offset);
                    null;

                };

                case (#Array(arr_type), #Array(arr_values)) {
                    primitive_type_buffer.add(T.TypeCode.Array);
                    let code = get_type_code_or_ref(arr_type, type_buffer, unique_map, recursive_map);

                    unsigned_leb128(value_buffer, arr_values.size());

                    var i = 0;
                    while (i < arr_values.size()) {
                        let hash = encode(
                            arr_type,
                            arr_values[i],
                            type_buffer,
                            primitive_type_buffer,
                            value_buffer,
                            renaming_map,
                            unique_map,
                            recursive_map,
                        );
                        // if (hash == null) return null;
                        // unsigned_leb128(value_buffer, hash);
                        i += 1;
                    };

                };

                case (#Record(field_types), #Record(field_values)) {

                };
            };
        };

    };

    type InternalTypeNode = {
        type_ : InternalType;
        height : Nat;
        parent_index : Nat;
        tag : Tag;
    };

    type TypeNode = {
        type_ : Type;
        height : Nat;
        parent_index : Nat;
        tag : Tag;
    };

    public func toArgs(candid_values : [Candid], renaming_map : TrieMap<Text, Text>) : Result<[Arg], Text> {
        let buffer = Buffer.Buffer<Arg>(candid_values.size());

        Debug.print("convert ... ");
        for (candid in candid_values.vals()) {
            let (internal_arg_type, arg_value) = toArgTypeAndValue(candid, renaming_map);

            Debug.print("get internal arg type and value");

            let rows = Buffer.Buffer<[InternalTypeNode]>(8);

            let node : InternalTypeNode = {
                type_ = internal_arg_type;
                height = 0;
                parent_index = 0;
                tag = #name("");
            };
            Debug.print("init node");

            rows.add([node]);

            order_types_by_height_bfs(rows);
            Debug.print("order types by height");

            let res = merge_variants_and_array_types(rows);
            Debug.print("merge variants and array types");
            let #ok(merged_type) = res else return Utils.send_error(res);

            buffer.add({ type_ = merged_type; value = arg_value });
            Debug.print("add to buffer");
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

    func to_record_field_type(node : TypeNode) : RecordFieldType = {
        type_ = node.type_;
        tag = node.tag;
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

    func get_height_value(type_ : InternalType) : Nat {
        switch (type_) {
            case (#empty or #null_) 0;
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

    func get_renamed_key(renaming_map : TrieMap<Text, Text>, key : Text) : Text {
        switch (renaming_map.get(key)) {
            case (?v) v;
            case (_) key;
        };
    };
};
