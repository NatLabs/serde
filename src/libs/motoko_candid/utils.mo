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
import TrieMap "mo:base/TrieMap";
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

import T "../../Candid/Types";
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
    type Iter<A> = Iter.Iter<A>;
    type Hash = Nat32;
    type Map<K, V> = Map.Map<K, V>;
    type Order = Order.Order;

    type Candid = T.Candid;
    type CandidType = T.CandidType;
    type KeyValuePair = T.KeyValuePair;
    public func toArgType(candid : CandidType) : (Type.Type) {
        let (arg_type) : (Type.Type) = switch (candid) {
            case (#Nat) (#nat);
            case (#Nat8) (#nat8);
            case (#Nat16) (#nat16);
            case (#Nat32) (#nat32);
            case (#Nat64) (#nat64);

            case (#Int) (#int);
            case (#Int8) (#int8);
            case (#Int16) (#int16);
            case (#Int32) (#int32);
            case (#Int64) (#int64);

            case (#Float) (#float64);

            case (#Bool) (#bool);

            case (#Principal) (#principal);

            case (#Text) (#text);

            case (#Null) (#null_);
            case (#Empty) (#empty);

            case (#Blob(blob)) #vector(#nat8);

            case (#Option(optType)) #opt(toArgType(optType));
            case (#Array(arr_type)) #vector(toArgType(arr_type));

            case (#Record(records) or #Map(records)) #record(
                Array.map(
                    records,
                    func((key, val) : (Text, CandidType)) : Type.RecordFieldType = {
                        tag = #name(key);
                        type_ = toArgType(val);
                    },
                )
            );

            case (#Variant(variants)) #variant(
                Array.map(
                    variants,
                    func((key, val) : (Text, CandidType)) : Type.RecordFieldType = {
                        tag = #name(key);
                        type_ = toArgType(val);
                    },
                )
            );
        };
    };
    public func toArgs(candid_values : [Candid], renaming_map : TrieMap<Text, Text>) : Result<[Arg], Text> {
        let buffer = Buffer.Buffer<Arg>(candid_values.size());

        for (candid in candid_values.vals()) {
            let (internal_arg_type, arg_value) = toArgTypeAndValue(candid, renaming_map);

            let rows = Buffer.Buffer<[InternalTypeNode]>(8);

            let node : InternalTypeNode = {
                type_ = internal_arg_type;
                height = 0;
                parent_index = 0;
                tag = #name("");
            };

            rows.add([node]);

            order_types_by_height_bfs(rows);

            let res = merge_variants_and_array_types(rows);
            let #ok(merged_type) = res else return Utils.send_error(res);

            buffer.add({ type_ = merged_type; value = arg_value });
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

            case (#Tuple(tuples)) {
                var i = 0;
                let record = #Record(
                    Array.map<Candid, (Text, Candid)>(
                        tuples,
                        func((tuple) : Candid) : (Text, Candid) {
                            let key = debug_show(i);
                            i+= 1;
                            (key, tuple);
                        },
                    )
                );

                toArgTypeAndValue(record, renaming_map);
            }
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

    type TypeNode = {
        type_ : Type;
        height : Nat;
        parent_index : Nat;
        tag : Tag;
    };

    type InternalTypeNode = {
        type_ : InternalType;
        height : Nat;
        parent_index : Nat;
        tag : Tag;
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
