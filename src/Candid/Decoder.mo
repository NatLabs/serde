import Array "mo:base/Array";
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

import T "Types";
import U "../Utils";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;

    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    public func decode(blob : Blob, recordKeys : [Text]) : Candid {
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
            func(n : Nat32) : Hash.Hash = n,
        );

        switch (res) {
            case (?args) {
                Debug.print("Candid decode args: " # debug_show (args));
                fromArgs(args, recordKeyMap);
            };
            case (_) { Prelude.unreachable() };
        };
    };

    public func fromArgs(args : [Arg], recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Candid {
        let arg = args[0];

        fromArgValue(arg.value, recordKeyMap);
    };

    func fromArgValue(val : Value, recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Candid {
        switch (val) {
            case (#nat(n)) #Nat(n);
            case (#nat8(n)) #Nat8(n);
            case (#nat16(n)) #Nat16(n);
            case (#nat32(n)) #Nat32(n);
            case (#nat64(n)) #Nat64(n);

            case (#int(n)) #Int(n);
            case (#int8(n)) #Int8(n);
            case (#int16(n)) #Int16(n);
            case (#int32(n)) #Int32(n);
            case (#int64(n)) #Int64(n);

            case (#float64(n)) #Float(n);

            case (#bool(b)) #Bool(b);

            case (#principal(service)) {
                switch (service) {
                    case (#transparent(p)) {
                        #Principal(p);
                    };
                    case (_) Prelude.unreachable();
                };
            };

            case (#text(n)) #Text(n);

            case (#_null) #Null;

            case (#opt(optVal)) {
                let val = switch (optVal) {
                    case (?val) {
                        fromArgValue(val, recordKeyMap);
                    };
                    case (_) #Null;
                };

                #Option(val);
            };
            case (#vector(arr)) {
                let newArr = Array.map(
                    arr,
                    func(elem : Value) : Candid {
                        fromArgValue(elem, recordKeyMap);
                    },
                );

                #Array(newArr);
            };

            case (#record(records)) {
                let newRecords = Array.map(
                    records,
                    func({ tag; value } : RecordFieldValue) : KeyValuePair {
                        let key = getKey(tag, recordKeyMap);
                        let val = fromArgValue(value, recordKeyMap);

                        (key, val);
                    },
                );

                #Record(Array.sort(newRecords, U.cmpRecords));
            };

            case (#variant({ tag; value })) {
                let key = getKey(tag, recordKeyMap);
                let val = fromArgValue(value, recordKeyMap);

                #Variant((key, val));
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
