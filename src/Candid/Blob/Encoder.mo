import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";

import Encoder "mo:candid/Encoder";
import Decoder "mo:candid/Decoder";
import Arg "mo:candid/Arg";
import Value "mo:candid/Value";
import Type "mo:candid/Type";

import T "../Types";
import U "../../Utils";
import TrieMap "mo:base/TrieMap";
import Utils "../../Utils";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<A, B> = Result.Result<A, B>;

    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    public func encode(candid_values : [Candid], options: ?T.Options) : Result<Blob, Text> {
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

    public func encodeOne(candid : Candid, options: ?T.Options) : Result<Blob, Text> {
        encode([candid], options);
    };

    public func toArgs(candid_values : [Candid], renaming_map: TrieMap<Text, Text>) : Result<[Arg], Text> {
        let buffer = Buffer.Buffer<Arg>(candid_values.size());

        for (candid in candid_values.vals()) {
            let type_res = toArgType(candid, renaming_map);
            let #ok(type_) = type_res else return Utils.send_error(type_res);

            let value_res = toArgValue(candid, renaming_map);
            let #ok(value) = value_res else return Utils.send_error(value_res);

            buffer.add({type_; value});
        };

        #ok(Buffer.toArray(buffer));
    };

    func toArgType(candid : Candid, renaming_map: TrieMap<Text, Text>) : Result<Type, Text> {
        let arg_type: Type = switch (candid) {
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

                #variant([ { tag = #name(renamed_key); type_; } ]);
            };

            case (#Empty) #empty;
        };

        #ok(arg_type);
    };

    func toArgValue(candid : Candid, renaming_map: TrieMap<Text, Text>) : Result<Value, Text> {
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

                for (item in arr.vals()){
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

                for ((record_key, record_val) in records.vals()){
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

    func get_renamed_key(renaming_map: TrieMap<Text, Text>, key: Text) : Text {
        switch (renaming_map.get(key)) {
            case (?v) v;
            case (_) key;
        };
    }
};
