import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";

import Encoder "mo:candid/Encoder";
import Decoder "mo:candid/Decoder";
import Arg "mo:candid/Arg";
import Value "mo:candid/Value";
import Type "mo:candid/Type";
import Tag "mo:candid/Tag";
import BufferDeque "mo:buffer-deque/BufferDeque";
import Itertools "mo:itertools/Iter";
import PeekableIter "mo:itertools/PeekableIter";

import T "../Types";
import U "../../Utils";
import TrieMap "mo:base/TrieMap";
import Utils "../../Utils";
import Order "mo:base/Order";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Tag = Tag.Tag;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<A, B> = Result.Result<A, B>;
    type BufferDeque<A> = BufferDeque.BufferDeque<A>;
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

    public func toArgs(candid_values : [Candid], renaming_map : TrieMap<Text, Text>) : Result<[Arg], Text> {
        let buffer = Buffer.Buffer<Arg>(candid_values.size());

        for (candid in candid_values.vals()) {
            let type_res = toArgTypeWithHeight(candid, renaming_map);
            let #ok(type_, height) = type_res else return Utils.send_error(type_res);

            let value_res = toArgValue(candid, renaming_map);
            let #ok(value) = value_res else return Utils.send_error(value_res);

            buffer.add({ type_; value });
        };

        #ok(Buffer.toArray(buffer));
    };

    func toArgType(candid : Candid, renaming_map : TrieMap<Text, Text>) : Result<Type, Text> {
        let arg_type : Type = switch (candid) {
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
            case (#Blob(_)) #vector(#nat8);

            case (#Null) #null_;

            case (#Option(optType)) {
                let res = toArgType(optType, renaming_map);
                let #ok(type_) = res else return Utils.send_error(res);
                #opt(type_);
            };
            case (#Array(arr)) {
                if (arr.size() > 0) {
                    let res = toArgType(arr[0], renaming_map);
                    let #ok(vector_type) = res else return Utils.send_error(res);
                    #vector(vector_type);
                } else {
                    #vector(#empty);
                };
            };

            case (#Record(records)) {
                let newRecords = Buffer.Buffer<RecordFieldType>(records.size());

                for ((key, val) in records.vals()) {
                    let renamed_key = get_renamed_key(renaming_map, key);

                    let res = toArgType(val, renaming_map);
                    let #ok(type_) = res else return Utils.send_error(res);

                    newRecords.add({
                        tag = #name(renamed_key);
                        type_;
                    });
                };

                #record(Buffer.toArray(newRecords));
            };

            case (#Variant((key, val))) {
                let renamed_key = get_renamed_key(renaming_map, key);

                let res = toArgType(val, renaming_map);
                let #ok(type_) = res else return Utils.send_error(res);

                #variant([{ tag = #name(renamed_key); type_ }]);
            };

            case (#Empty) #empty;
        };

        #ok(arg_type);
    };

    // Include the height of the tree in the type
    // to choose the best for data that might have different heights like optional types
    // types like #Null and #Empty should have height 0
    func toArgTypeWithHeight(candid : Candid, renaming_map : TrieMap<Text, Text>) : Result<(Type, height : Nat), Text> {
        var curr_height = 0;

        let arg_type : Type = switch (candid) {
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
            case (#Blob(_)) #vector(#nat8);

            case (#Null) return #ok(#null_, 0);
            case (#Empty) return #ok(#empty, 0);

            case (#Option(optType)) {
                let res = toArgTypeWithHeight(optType, renaming_map);
                let #ok(type_, height) = res else return Utils.send_error(res);
                curr_height := height;

                #opt(type_);
            };
            case (#Array(arr)) {
                if (arr.size() == 0) return #ok(#vector(#empty), 1);

                let max = {
                    var height = 0;
                    var type_ : Type = #empty;
                };

                let buffer = Buffer.Buffer<TypeInfo>(arr.size());
                for ((id, item) in Itertools.enumerate(arr.vals())) {
                    let res = toArgTypeWithHeight(item, renaming_map);
                    let #ok(type_, height) = res else return Utils.send_error(res);
                    buffer.add((type_, id, #name("")));

                    if (height > max.height) {
                        max.height := height;
                        max.type_ := type_;
                    };
                };

                buffer.sort(func ((a, _, _), (b, _, _)) : Order.Order = if (a == max.type_) { #less } else { #greater });

                let rows = Buffer.Buffer<[TypeInfo]>(8);
                rows.add(Buffer.toArray(buffer));
                Debug.print("rows before bfs: \n" # debug_show Buffer.toArray(rows));

                bfs_get_types_by_height(rows);
                Debug.print("rows after bfs: \n" # debug_show Buffer.toArray(rows));

                let merged_type = merge_variants_in_array_type(rows);

                Debug.print("rows: \n" # debug_show Buffer.toArray(rows));
                
                curr_height := max.height;

                #vector(merged_type);
            };

            case (#Record(records)) {
                let newRecords = Buffer.Buffer<RecordFieldType>(records.size());

                for ((key, val) in records.vals()) {
                    let renamed_key = get_renamed_key(renaming_map, key);

                    let res = toArgTypeWithHeight(val, renaming_map);
                    let #ok(type_, height) = res else return Utils.send_error(res);

                    curr_height := height;

                    newRecords.add({
                        tag = #name(renamed_key);
                        type_;
                    });
                };

                #record(Buffer.toArray(newRecords));
            };

            case (#Variant((key, val))) {
                let renamed_key = get_renamed_key(renaming_map, key);

                let res = toArgTypeWithHeight(val, renaming_map);
                let #ok(type_, height) = res else return Utils.send_error(res);

                curr_height := height;
                #variant([{ tag = #name(renamed_key); type_ }]);
            };

        };

        #ok(arg_type, curr_height + 1);
    };

    type TypeInfo = (Type, id: Nat, tag: Tag);

    func merge_variants_in_array_type(types : Buffer<[TypeInfo]>) : Type {
        let buffer = Buffer.Buffer<TypeInfo>(types.size());
        Debug.print("types.size(): " # debug_show types.size());
        Debug.print("types: " # debug_show Buffer.toArray(types));
        let ?_bottom = types.removeLast() else return #empty;
        var bottom = _bottom;

        var variants_exist = false;

        while (types.size() > 0){
            Debug.print("bottom" # debug_show bottom);

            let ?above_bottom = types.removeLast() else return Prelude.unreachable();
            var bottom_iter = bottom.vals() |> Itertools.peekable(_);

            let variants = Buffer.Buffer<RecordFieldType>(bottom.size());
            let variant_indexes = Buffer.Buffer<Nat>(bottom.size());


            for ((index, (compound_type, parent_id, parent_tag)) in Itertools.enumerate(above_bottom.vals())){
                let tmp_bottom_iter = PeekableIter.takeWhile(bottom_iter, func((_, id, tag) : TypeInfo) : Bool = index == id);

                switch(compound_type){
                    case (#opt(_)) {
                        let ?(opt_val, _, _) = tmp_bottom_iter.next() else return Prelude.unreachable();
                        buffer.add((#opt(opt_val), parent_id, parent_tag));
                    };
                    case (#vector(_)) {
                        let ?(vec_type, _, _) = tmp_bottom_iter.next() else return Prelude.unreachable();

                        buffer.add((#vector(vec_type), parent_id, parent_tag));
                    };
                    case (#record(_)) {
                        let record_type = tmp_bottom_iter 
                            |> Iter.map(_, func((type_, _, tag) : TypeInfo) : RecordFieldType = {type_; tag})
                            |> Iter.toArray(_);

                        buffer.add((#record(record_type), parent_id, parent_tag));
                    };
                    case (#variant(_)) {
                        variants_exist := true;
                        let variant_types = tmp_bottom_iter 
                            |> Iter.map(_, func((type_, _, tag) : TypeInfo) : RecordFieldType = {type_; tag})
                            |> Iter.toArray(_);

                        for (variant_type in variant_types.vals()) {
                            variants.add(variant_type);
                        };

                        variant_indexes.add(buffer.size());

                        buffer.add((#variant(variant_types), parent_id, parent_tag));

                    };
                    case (_){
                        buffer.add(compound_type, parent_id, parent_tag);
                    };
                };
            };

            if (variants.size() > 0) {
                let full_variant_type : Type = #variant(Buffer.toArray(variants));

                for (index in variant_indexes.vals()){
                    let (_, prev_id, prev_tag) = buffer.get(index);
                    buffer.put(index, (full_variant_type, prev_id, prev_tag));
                }; 

            };
            
            bottom := Buffer.toArray(buffer);
            buffer.clear();
        };

        Debug.print("bottom" # debug_show bottom);

        bottom[0].0;
    };

    func bfs_get_types_by_height(types : Buffer<[TypeInfo]>) {

        var merged_type : ?Type = null;

        label while_loop 
        while (types.size() > 0) {
            let ?candid_values = types.removeLast() else return Prelude.unreachable();
            let buffer = Buffer.Buffer<TypeInfo>(8);

            var has_compound_type = false;

            for ((id, (candid, _, tag)) in Itertools.enumerate(candid_values.vals())) {
                switch (candid) {
                    case (#opt(opt_val)) {
                        has_compound_type := true;
                        buffer.add((opt_val, id, #name("")));
                    };
                    case (#vector(vec_type)) {
                        has_compound_type := true;
                        buffer.add((vec_type, id, #name("")));
                    };
                    case (#record(records)) {
                        for ({tag; type_} in records.vals()) {
                            has_compound_type := true;
                            buffer.add((type_, id, tag));
                        };
                    };
                    case (#variant(variants)) {
                        has_compound_type := true;
                        for ({tag; type_} in variants.vals()) {
                            has_compound_type := true;
                            buffer.add((type_, id, tag));
                        };
                    };
                    case (_) {};
                };
            };

            types.add(candid_values);

            if (has_compound_type) {
                types.add(Buffer.toArray(buffer));
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
