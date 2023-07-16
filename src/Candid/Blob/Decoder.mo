import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";

import Encoder "mo:candid/Encoder";
import Decoder "mo:candid/Decoder";

import Arg "mo:candid/Arg";
import Value "mo:candid/Value";
import Type "mo:candid/Type";
import Tag "mo:candid/Tag";

import { hashName } "mo:candid/Tag";

import T "../Types";
import U "../../Utils";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;

    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    /// Decodes a blob encoded in the candid format into a list of the [Candid](./Types.mo#Candid) type in motoko
    /// 
    /// ### Inputs
    /// - **blob** -  A blob encoded in the candid format
    /// - **record_keys** - The record keys to use when decoding a record.
    /// - **options** - An optional arguement to specify options for decoding.

    public func decode(blob : Blob, record_keys: [Text], options: ?T.Options) : [Candid] {
        let res = Decoder.decode(blob);

        let renaming_map : TrieMap<Text, Text> = switch (options) {
            case (?{renameKeys}) TrieMap.fromEntries(renameKeys.vals(), Text.equal, Text.hash);
            case (_) TrieMap.TrieMap(Text.equal, Text.hash);
        };

        let keyEntries = Iter.map<Text, (Nat32, Text)>(
            record_keys.vals(),
            func(original_key : Text) : (Nat32, Text) {
                let new_key = switch(renaming_map.get(original_key)) {
                    case (?key) key;
                    case (_) original_key;
                };

                (hashName(original_key), new_key);
            },
        );

        let recordKeyMap = TrieMap.fromEntries<Nat32, Text>(
            keyEntries,
            Nat32.equal,
            func(n : Nat32) : Hash.Hash = n,
        );

        switch (res) {
            case (?args) fromArgs(args, recordKeyMap);
            case (_) Debug.trap("Failed to decode candid blob");
        };
    };

    public func fromArgs(args : [Arg], recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : [Candid] {
        Array.map(
            args,
            func(arg : Arg) : Candid {
                fromArgType(arg._type, arg.value, recordKeyMap);
            },
        )
    };

    func fromArgType(_type : Type, val : Value, recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Candid {
        switch (_type, val) {
            case (_, #nat(n)) #Nat(n);
            case (_, #nat8(n)) #Nat8(n);
            case (_, #nat16(n)) #Nat16(n);
            case (_, #nat32(n)) #Nat32(n);
            case (_, #nat64(n)) #Nat64(n);

            case (_, #int(n)) #Int(n);
            case (_, #int8(n)) #Int8(n);
            case (_, #int16(n)) #Int16(n);
            case (_, #int32(n)) #Int32(n);
            case (_, #int64(n)) #Int64(n);

            case (_, #float64(n)) #Float(n);

            case (_, #bool(b)) #Bool(b);

            case (_, #principal(service)) {
                switch (service) {
                    case (#transparent(p)) {
                        #Principal(p);
                    };
                    case (_) Prelude.unreachable();
                };
            };

            case (_, #text(n)) #Text(n);

            case (_, #_null) #Null;

            case (optionType, #opt(optVal)) {
                let val = switch (optionType, optVal) {
                    case (#opt(#_null), _) #Null;
                    case (#opt(_), null) #Null;
                    case (#opt(innerType), ?val) {
                        fromArgType(innerType, val, recordKeyMap);
                    };
                    case (_) Debug.trap("Expected value in #opt");
                };

                #Option(val);
            };
            case (vectorType, #vector(arr)) {

                switch (vectorType) {
                    case (#vector(#nat8)) {
                        let bytes = Array.map(
                            arr,
                            func(elem : Value) : Nat8 {
                                switch (elem) {
                                    case (#nat8(n)) n;
                                    case (_) Debug.trap("Expected nat8 in #vector");
                                };
                            },
                        );

                        let blob = Blob.fromArray(bytes);
                        return #Blob(blob);
                    };
                    case (#vector(innerType)) {
                        let newArr = Array.map(
                            arr,
                            func(elem : Value) : Candid {
                                fromArgType(innerType, elem, recordKeyMap);
                            },
                        );

                        return #Array(newArr);
                    };
                    case (_) Debug.trap("Mismatched type '" # debug_show (vectorType)# "'' to value of '#vector'");
                };
            };

            case (#record(recordTypes), #record(records)) {
                let newRecords = Array.tabulate(
                    records.size(),
                    func (i: Nat): KeyValuePair {
                        let {_type = innerType} = recordTypes[i];
                        let {tag; value} = records[i];

                        let key = getKey(tag, recordKeyMap);
                        let val = fromArgType(innerType, value, recordKeyMap);

                        (key, val)
                    },
                ); 
                
                #Record(Array.sort(newRecords, U.cmpRecords));
            };

            case (#variant(variantTypes), #variant(v)) {
                
                for ({tag; _type = innerType} in variantTypes.vals()) {
                    if (tag == v.tag) {
                        let key = getKey(tag, recordKeyMap);
                        let val = fromArgType(innerType, v.value, recordKeyMap);

                        return #Variant((key, val));
                    };
                };

                Debug.trap("Could not find variant type for '" # debug_show v.tag # "'");
            };

            case (_) { Prelude.unreachable() };
        };
    };

    func getKey(tag : Tag.Tag, recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Text {
        switch (tag) {
            case (#hash(hash)) {
                switch (recordKeyMap.get(hash)) {
                    case (?key) key;
                    case (_) debug_show hash;
                };
            };
            case (#name(key)) key;
        };
    };

};
