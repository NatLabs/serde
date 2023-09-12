import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";

import Encoder "mo:candid/Encoder";
import Decoder "mo:candid/Decoder";
import Arg "mo:candid/Arg";
import Value "mo:candid/Value";
import Type "mo:candid/Type";
import Tag "mo:candid/Tag";
import Itertools "mo:itertools/Iter";
import PeekableIter "mo:itertools/PeekableIter";

import T "../Types";
import U "../../Utils";
import TrieMap "mo:base/TrieMap";
import Utils "../../Utils";
import Order "mo:base/Order";
import Func "mo:base/Func";

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

    public func encode(candid_values : [Candid], options : ?T.Options) : Result<Blob, Text> {
        let renaming_map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        ignore do ? {
            let renameKeys = options!.renameKeys;
            for ((k, v) in renameKeys.vals()) {
                renaming_map.put(k, v);
            };
        };

        let res = toArgs(candid_values, renaming_map);
        let #ok(args) = res else return Utils.send_error(res);

        #ok(Encoder.encode(args));
    };

    public func encodeOne(candid : Candid, options : ?T.Options) : Result<Blob, Text> {
        encode([candid], options);
    };

    type UpdatedTypeNode = {
        var type_ : UpdatedType;
        height : Nat;
        parent_index : Nat;
        var children : ?{
            start : Nat;
            n : Nat;
        };
        tag : Tag;
    };

    type TypeNode = {
        var type_ : Type;
        height : Nat;
        parent_index : Nat;
        var children : ?{
            start : Nat;
            n : Nat;
        };
        tag : Tag;
    };

    public func toArgs(candid_values : [Candid], renaming_map : TrieMap<Text, Text>) : Result<[Arg], Text> {
        let buffer = Buffer.Buffer<Arg>(candid_values.size());

        for (candid in candid_values.vals()) {
            let updated_arg_type = toUpdatedArgType(candid, renaming_map);

            let rows = Buffer.Buffer<[UpdatedTypeNode]>(8);
            let node : UpdatedTypeNode = {
                var type_ = updated_arg_type;
                height = 0;
                parent_index = 0;
                var children = null;
                tag = #name("");
            };

            rows.add([node]);
            order_types_by_height_bfs(rows);

            let merged_type = merge_variants_in_array_type(rows);

            let value_res = toArgValue(candid, renaming_map);
            let #ok(value) = value_res else return Utils.send_error(value_res);

            buffer.add({ type_ = merged_type; value });
        };

        #ok(Buffer.toArray(buffer));
    };

    type UpdatedKeyValuePair = { tag : Tag; type_ : UpdatedType };

    type UpdatedCompoundType = {
        #opt : UpdatedType;
        #vector : [UpdatedType];
        #record : [UpdatedKeyValuePair];
        #variant : [UpdatedKeyValuePair];
        // #func_ : Type.FuncType;
        // #service : Type.ServiceType;
        // #recursiveType : { id : Text; type_ : UpdatedType };
        // #recursiveReference : Text;
    };

    type UpdatedType = Type.PrimitiveType or UpdatedCompoundType;

    func extract_top_level_type(type_ : UpdatedType) : (UpdatedType) {
        switch (type_) {
            case (#bool(_)) #bool;

            case (#principal(_)) #principal;

            case (#text(_)) #text;

            case (#null_) return #null_;
            case (#empty) return #empty;

            case (#opt(_)) #opt(#empty);
            case (#vector(_)) #vector([]);
            case (#record(_)) #record([]);
            case (#variant(_)) #variant([]);
            case (x) x;
        };
    };

    func toUpdatedArgType(candid : Candid, renaming_map : TrieMap<Text, Text>) : UpdatedType {
        var curr_height = 0;

        let arg_type : UpdatedType = switch (candid) {
            case (#Nat(_)) #nat;
            case (#Nat8(_)) #nat8;
            case (#Nat16(_)) #nat16;
            case (#Nat32(_)) #nat32;
            case (#Nat64(_)) #nat64;

            case (#Int(_)) #int;
            case (#Int8(_)) #int8;
            case (#Int16(_)) #int16;
            case (#Int32(_)) #int32;
            case (#Int64(_)) #int64;

            case (#Float(_)) #float64;

            case (#Bool(_)) #bool;

            case (#Principal(_)) #principal;

            case (#Text(_)) #text;
            case (#Blob(_)) #vector([#nat8]);

            case (#Null) #null_;
            case (#Empty) #empty;

            case (#Option(optType)) {
                let type_ = toUpdatedArgType(optType, renaming_map);
                #opt(type_);
            };
            case (#Array(arr)) {
                let vec_types = Array.map<Candid, UpdatedType>(
                    arr,
                    func(item : Candid) : UpdatedType = toUpdatedArgType(item, renaming_map),
                );

                #vector(vec_types);
            };

            case (#Record(records)) {
                let newRecords : Buffer<UpdatedKeyValuePair> = Buffer.Buffer(records.size());

                for ((key, val) in records.vals()) {
                    let renamed_key = get_renamed_key(renaming_map, key);

                    let type_ = toUpdatedArgType(val, renaming_map);

                    newRecords.add({
                        tag = #name(renamed_key);
                        type_;
                    });
                };

                #record(Buffer.toArray(newRecords));
            };

            case (#Variant((key, val))) {
                let renamed_key = get_renamed_key(renaming_map, key);
                let type_ = toUpdatedArgType(val, renaming_map);
                #variant([{ tag = #name(renamed_key); type_ }]);
            };

        };

        arg_type;
    };

    func updated_type_to_arg_type(updated_type : UpdatedType, vec_index : ?Nat) : Type {
        switch (updated_type, vec_index) {
            case (#vector(vec_types), ?vec_index) #vector(updated_type_to_arg_type(vec_types[vec_index], null));
            case (#vector(vec_types), _) #vector(updated_type_to_arg_type(vec_types[0], null));
            case (#opt(opt_type), _) #opt(updated_type_to_arg_type(opt_type, null));
            case (#record(record_types), _) {
                let new_record_types = Array.map<UpdatedKeyValuePair, RecordFieldType>(
                    record_types,
                    func({ type_; tag } : UpdatedKeyValuePair) : RecordFieldType = {
                        type_ = updated_type_to_arg_type(type_, null);
                        tag;
                    },
                );

                #record(new_record_types);
            };
            case (#variant(variant_types), _) {
                let new_variant_types = Array.map<UpdatedKeyValuePair, RecordFieldType>(
                    variant_types,
                    func({ type_; tag } : UpdatedKeyValuePair) : RecordFieldType = {
                        type_ = updated_type_to_arg_type(type_, null);
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

    func merge_variants_in_array_type(rows : Buffer<[UpdatedTypeNode]>) : Type {
        let buffer = Buffer.Buffer<TypeNode>(8);
        let total_rows = rows.size();

        func calc_height(parent : Nat, child : Nat) : Nat = parent + child;

        let ?_bottom = rows.removeLast() else return Debug.trap("trying to pop bottom but rows is empty");

        var bottom = Array.map(
            _bottom,
            func(node : UpdatedTypeNode) : TypeNode = {
                var type_ = updated_type_to_arg_type(node.type_, null);
                height = node.height;
                parent_index = node.parent_index;
                var children = node.children;
                tag = node.tag;
            },
        );

        var variants_exist = false;
        
        while (rows.size() > 0) {

            let ?above_bottom = rows.removeLast() else return Debug.trap("trying to pop above_bottom but rows is empty");

            var bottom_iter = Itertools.peekable(bottom.vals());

            let variants = Buffer.Buffer<RecordFieldType>(bottom.size());
            let variant_indexes = Buffer.Buffer<Nat>(bottom.size());

            for ((index, parent_node) in Itertools.enumerate(above_bottom.vals())) {
                let tmp_bottom_iter = PeekableIter.takeWhile(bottom_iter, func({ parent_index; tag } : TypeNode) : Bool = index == parent_index);
                let { parent_index; tag = parent_tag } = parent_node;

                switch (parent_node.type_) {
                    case (#opt(_)) {
                        let ?child_node = tmp_bottom_iter.next() else return Debug.trap(" #opt error: no item in tmp_bottom_iter");

                        let merged_node : TypeNode = {
                            var type_ = #opt(child_node.type_);
                            height = calc_height(parent_node.height, child_node.height);
                            parent_index;
                            var children = null;
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
                            var type_ = #vector(max.type_);
                            height = calc_height(parent_node.height, max.height);
                            parent_index;
                            var children = null;
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

                        let record_type = tmp_bottom_iter
                            |> Iter.map(_, composed_fn)
                            |> Iter.toArray(_);

                        let merged_node : TypeNode = {
                            var type_ = #record(record_type);
                            height = calc_height(parent_node.height, height);
                            parent_index;
                            var children = null;
                            tag = parent_tag;
                        };
                        buffer.add(merged_node);
                    };
                    case (#variant(_)) {
                        variants_exist := true;

                        var height = 0;

                        func get_max_height(item : TypeNode) : TypeNode {
                            height := Nat.max(height, item.height);
                            item;
                        };

                        let composed_fn = Func.compose(to_record_field_type, get_max_height);

                        let variant_types = tmp_bottom_iter
                        |> Iter.map(_, composed_fn)
                        |> Iter.toArray(_);

                        for (variant_type in variant_types.vals()) {
                            variants.add(variant_type);
                        };

                        variant_indexes.add(buffer.size());

                        let merged_node : TypeNode = {
                            var type_ = #variant(variant_types);
                            height = calc_height(parent_node.height, height);
                            parent_index;
                            var children = null;
                            tag = parent_tag;
                        };

                        buffer.add(merged_node);

                    };
                    case (_) {
                        let new_parent_node : TypeNode = {
                            var type_ = updated_type_to_arg_type(parent_node.type_, null);
                            height = parent_node.height;
                            parent_index;
                            var children = null;
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
                        var type_ = full_variant_type;
                        height = prev_node.height;
                        parent_index = prev_node.parent_index;
                        var children = prev_node.children;
                        tag = prev_node.tag;
                    };

                    buffer.put(index, new_node);
                };
            };

            bottom := Buffer.toArray(buffer);
            buffer.clear();
        };

        let merged_type = bottom[0].type_;
        merged_type;
    };

    func get_height_value(type_ : UpdatedType) : Nat {
        switch (type_) {
            case (#empty or #null_) 0;
            case (_) 1;
        };
    };

    func order_types_by_height_bfs(rows : Buffer<[UpdatedTypeNode]>) {
        var merged_type : ?UpdatedType = null;

        label while_loop while (rows.size() > 0) {
            let candid_values = Buffer.last(rows) else return Prelude.unreachable();
            let buffer = Buffer.Buffer<UpdatedTypeNode>(8);

            var has_compound_type = false;

            for ((index, parent_node) in Itertools.enumerate(candid_values.vals())) {

                switch (parent_node.type_) {
                    case (#opt(opt_val)) {
                        has_compound_type := true;
                        let child_node : UpdatedTypeNode = {
                            var type_ = opt_val;
                            height = get_height_value(opt_val);
                            parent_index = index;
                            var children = null;
                            tag = #name("");
                        };

                        parent_node.children := ?{
                            start = buffer.size();
                            n = 1;
                        };
                        buffer.add(child_node);
                    };
                    case (#vector(vec_types)) {
                        has_compound_type := true;

                        parent_node.children := ?{
                            start = buffer.size();
                            n = vec_types.size();
                        };

                        for (vec_type in vec_types.vals()) {
                            let child_node : UpdatedTypeNode = {
                                var type_ = vec_type;
                                height = get_height_value(vec_type);
                                parent_index = index;
                                var children = null;
                                tag = #name("");
                            };

                            buffer.add(child_node);
                        };

                    };
                    case (#record(records)) {

                        parent_node.children := ?{
                            start = buffer.size();
                            n = records.size();
                        };

                        for ({ tag; type_ } in records.vals()) {
                            has_compound_type := true;
                            let child_node : UpdatedTypeNode = {
                                var type_ = type_;
                                height = get_height_value(type_);
                                parent_index = index;
                                var children = null;
                                tag;
                            };
                            buffer.add(child_node);
                        };
                    };
                    case (#variant(variants)) {
                        has_compound_type := true;
                        parent_node.children := ?{
                            start = buffer.size();
                            n = variants.size();
                        };
                        for ({ tag; type_ } in variants.vals()) {
                            has_compound_type := true;
                            let child_node : UpdatedTypeNode = {
                                var type_ = type_;
                                height = get_height_value(type_);
                                parent_index = index;
                                var children = null;
                                tag;
                            };
                            buffer.add(child_node);
                        };
                    };
                    case (_) {};
                };

                parent_node.type_ := extract_top_level_type(parent_node.type_);
            };

            if (has_compound_type) {
                rows.add(Buffer.toArray(buffer));
            } else {
                return;
            };
        };
    };

    func toArgValue(candid : Candid, renaming_map : TrieMap<Text, Text>) : Result<Value, Text> {
        let value : Value = switch (candid) {
            case (#Nat(n)) #nat(n);
            case (#Nat8(n)) #nat8(n);
            case (#Nat16(n)) #nat16(n);
            case (#Nat32(n)) #nat32(n);
            case (#Nat64(n)) #nat64(n);

            case (#Int(n)) #int(n);
            case (#Int8(n)) #int8(n);
            case (#Int16(n)) #int16(n);
            case (#Int32(n)) #int32(n);
            case (#Int64(n)) #int64(n);

            case (#Float(n)) #float64(n);

            case (#Bool(b)) #bool(b);

            case (#Principal(p)) #principal(p);

            case (#Text(n)) #text(n);

            case (#Null) #null_;

            case (#Option(optVal)) {
                let res = toArgValue(optVal, renaming_map);
                let #ok(val) = res else return Utils.send_error(res);
                #opt(val);
            };
            case (#Array(arr)) {
                let newArr = Buffer.Buffer<Value>(arr.size());

                for (item in arr.vals()) {
                    let res = toArgValue(item, renaming_map);
                    let #ok(val) = res else return Utils.send_error(res);
                    newArr.add(val);
                };

                #vector(Buffer.toArray(newArr));
            };

            case (#Blob(blob)) {
                let array = Blob.toArray(blob);

                let bytes = Array.map(
                    array,
                    func(elem : Nat8) : Value {
                        #nat8(elem);
                    },
                );

                #vector(bytes);
            };

            case (#Record(records)) {
                let newRecords = Buffer.Buffer<RecordFieldValue>(records.size());

                for ((record_key, record_val) in records.vals()) {
                    let renamed_key = get_renamed_key(renaming_map, record_key);

                    let res = toArgValue(record_val, renaming_map);
                    let #ok(value) = res else return Utils.send_error(res);

                    newRecords.add({
                        tag = #name(renamed_key);
                        value;
                    });
                };

                #record(Buffer.toArray(newRecords));
            };

            case (#Variant((key, val))) {
                let renamed_key = get_renamed_key(renaming_map, key);
                let res = toArgValue(val, renaming_map);
                let #ok(value) = res else return Utils.send_error(res);

                #variant({
                    tag = #name(renamed_key);
                    value;
                });
            };

            case (#Empty) #empty;

        };

        #ok(value);
    };

    func get_renamed_key(renaming_map : TrieMap<Text, Text>, key : Text) : Text {
        switch (renaming_map.get(key)) {
            case (?v) v;
            case (_) key;
        };
    };
};
