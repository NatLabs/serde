import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";

import Encoder "mo:motoko_candid/Encoder";
import Decoder "mo:motoko_candid/Decoder";

import Arg "mo:motoko_candid/Arg";
import Value "mo:motoko_candid/Value";
import Type "mo:motoko_candid/Type";

import { hashName } "mo:motoko_candid/Tag";

import T "Types";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;

    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    public func encode(blob : Blob, recordKeys : [Text]) : Candid {
        let res = Decoder.decode(blob);

        let keyEntries = Iter.map<Text, (Nat32, Text)>(
            recordKeys.vals(),
            func(key : Text) : (Nat32, Text) {
                (hashName(key), key);
            },
        );

        let recordKeyMap = TrieMap.fromEntries<Nat32, Text>(
            keyEntries,
            Nat32.equal,
            func(n : Nat32) : Hash.Hash {
                Hash.hash(Nat32.toNat(n));
            },
        );

        switch (res) {
            case (?args) {
                fromArgs(args, recordKeyMap);
            };
            case (_) { Prelude.unreachable() };
        };
    };

    func fromArgs(args : [Arg], recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Candid {
        let arg = args[0];

        fromArgValue(arg.value, recordKeyMap);
    };

    func fromArgValue(val : Value, recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Candid {
        switch (val) {
            case (#Nat(n)) #Nat(n);
            case (#Nat8(n)) #Nat8(n);
            case (#Nat16(n)) #Nat16(n);
            case (#Nat32(n)) #Nat32(n);
            case (#Nat64(n)) #Nat64(n);

            case (#Int(n)) #Int(n);
            case (#Int8(n)) #Int8(n);
            case (#Int16(n)) #Int16(n);
            case (#Int32(n)) #Int32(n);
            case (#Int64(n)) #Int64(n);

            case (#Float32(n)) #Float32(n);
            case (#Float64(n)) #Float64(n);

            case (#Bool(b)) #Bool(b);

            case (#Principal(service)) {
                switch (service) {
                    case (#transparent(p)) {
                        #Principal(p);
                    };
                    case (_) Prelude.unreachable();
                };
            };

            case (#Text(n)) #Text(n);

            case (#Null) #Null;

            case (#Option(optVal)) {
                let val = switch (optVal) {
                    case (?val) {
                        fromArgValue(val, recordKeyMap);
                    };
                    case (_) #Null;
                };

                #Option(val);
            };
            case (#Vector(arr)) {
                let newArr = Array.map(
                    arr,
                    func(elem : Value) : Candid {
                        fromArgValue(elem, recordKeyMap);
                    },
                );

                #Vector(newArr);
            };

            case (#Record(records)) {
                let newRecords = Array.map(
                    records,
                    func({ tag; value } : RecordFieldValue) : KeyValuePair {
                        switch (tag) {
                            case (#hash(hash)) {
                                let key = switch (recordKeyMap.get(hash)) {
                                    case (?key) key;
                                    case (_) debug_show hash;
                                };

                                let val = fromArgValue(value, recordKeyMap);

                                (key, val);
                            };
                            case (_) Prelude.unreachable();
                        };
                    },
                );

                #Record(newRecords);
            };

            // case (#Variant(variants)) {
            //     let (key, val) = variants[0];

            //     let res = {
            //         tag = #name(key);
            //         value = toArgValue(val);
            //     };

            //     #Variant(res);
            // };

            case (_) { Prelude.unreachable() };
        };
    };
};
