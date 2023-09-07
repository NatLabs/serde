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
    type Iter<A> = Iter.Iter<A>;

    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    /// Decodes a blob encoded in the candid format into a list of the [Candid](./Types.mo#Candid) type in motoko
    ///
    /// ### Inputs
    /// - **blob** -  A blob encoded in the candid format
    /// - **record_keys** - The record keys to use when decoding a record.
    /// - **options** - An optional arguement to specify options for decoding.

    public func decode(blob : Blob, record_keys : [Text], options : ?T.Options) : [Candid] {
        let keyEntries = Iter.map<Text, (Nat32, Text)>(
            formatVariantKeys(record_keys.vals()),
            func(key : Text) : (Nat32, Text) {
                (hashName(key), key);
            },
        );

        let recordKeyMap = TrieMap.fromEntries<Nat32, Text>(
            keyEntries,
            Nat32.equal,
            func(n : Nat32) : Hash.Hash = n,
        );

        ignore do ? {
            let key_pairs_to_rename = options!.renameKeys;

            let new_entries = Iter.map<(Text, Text), (Nat32, Text)>(
                key_pairs_to_rename.vals(),
                func(entry : (Text, Text)) : (Nat32, Text) {
                    let original_key = formatVariantKey(entry.0);
                    let new_key = formatVariantKey(entry.1);

                    (hashName(original_key), new_key);
                },
            );

            for ((hash, key) in new_entries) {
                recordKeyMap.put(hash, key);
            };
        };

        let res = Decoder.decode(blob);

        switch (res) {
            case (?args) fromArgs(args, recordKeyMap);
            case (_) Debug.trap("Candid Error: Failed to decode candid blob");
        };
    };

    func formatVariantKey(key : Text) : Text {
        let opt = Text.stripStart(key, #text("#"));
        switch (opt) {
            case (?stripped_text) stripped_text;
            case (null) key;
        };
    };

    func formatVariantKeys(record_keys_iter : Iter<Text>) : Iter<Text> {
        Iter.map(
            record_keys_iter,
            formatVariantKey,
        );
    };

    public func fromArgs(args : [Arg], recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : [Candid] {
        Array.map(
            args,
            func(arg : Arg) : Candid {
                fromArg(arg.type_, arg.value, recordKeyMap);
            },
        );
    };

    func fromArg(type_ : Type, val : Value, recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Candid {
        switch (type_, val) {
            case ((#recursiveReference(_) or #nat), #nat(n)) #Nat(n);
            case ((#recursiveReference(_) or #nat8), #nat8(n)) #Nat8(n);
            case ((#recursiveReference(_) or #nat16), #nat16(n)) #Nat16(n);
            case ((#recursiveReference(_) or #nat32), #nat32(n)) #Nat32(n);
            case ((#recursiveReference(_) or #nat64), #nat64(n)) #Nat64(n);

            case ((#recursiveReference(_) or #int), #int(n)) #Int(n);
            case ((#recursiveReference(_) or #int8), #int8(n)) #Int8(n);
            case ((#recursiveReference(_) or #int16), #int16(n)) #Int16(n);
            case ((#recursiveReference(_) or #int32), #int32(n)) #Int32(n);
            case ((#recursiveReference(_) or #int64), #int64(n)) #Int64(n);

            case ((#recursiveReference(_) or #float64), #float64(n)) #Float(n);

            case ((#recursiveReference(_) or #bool), #bool(b)) #Bool(b);

            case ((#recursiveReference(_) or #principal), #principal(p)) #Principal(p);

            case ((#recursiveReference(_) or #text), #text(n)) #Text(n);

            case ((#recursiveReference(_) or #null_), #null_) #Null;
            case ((#recursiveReference(_) or #empty), #empty) #Empty;
            
            // option
            case (_, #opt(#null_)) { #Option(#Null) };

            case (#opt(innerType), #opt(optVal)) {
                let val = fromArg(innerType, optVal, recordKeyMap);
                #Option(val);
            };

            case (#recursiveReference(ref_id), #opt(optVal)){
                let val = fromArg(#recursiveReference(ref_id), optVal, recordKeyMap);
                #Option(val);
            };

            // #vector
            // #vector(#nat8) -> blob
            case (#vector(#nat8), #vector(arr)) {
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
            case (#vector(innerType), #vector(arr)) {
                let newArr = Array.map(
                    arr,
                    func(elem : Value) : Candid {
                        fromArg(innerType, elem, recordKeyMap);
                    },
                );

                return #Array(newArr);
            };
            case (#recursiveReference(ref_id), #vector(arr)) {
                let newArr = Array.map(
                    arr,
                    func(elem : Value) : Candid {
                        fromArg(#recursiveReference(ref_id), elem, recordKeyMap);
                    },
                );

                return #Array(newArr);
            };

            // #record
            case (#record(recordTypes), #record(records)) {
                let newRecords = Array.tabulate(
                    records.size(),
                    func(i : Nat) : KeyValuePair {
                        let { type_ = innerType } = recordTypes[i];
                        let { tag; value } = records[i];

                        let key = getKey(tag, recordKeyMap);
                        let val = fromArg(innerType, value, recordKeyMap);

                        (key, val);
                    },
                );

                #Record(Array.sort(newRecords, U.cmpRecords));
            };

            case (#recursiveReference(ref_id), #record(records)) {
                let newRecords = Array.tabulate(
                    records.size(),
                    func(i : Nat) : KeyValuePair {
                        let { tag; value } = records[i];

                        let key = getKey(tag, recordKeyMap);
                        let val = fromArg(#recursiveReference(ref_id), value, recordKeyMap);

                        (key, val);
                    },
                );

                #Record(Array.sort(newRecords, U.cmpRecords));
            };

            case ( #variant(variantTypes), #variant(v)) {

                for ({ tag; type_ = innerType } in variantTypes.vals()) {
                    if (tag == v.tag) {
                        let key = getKey(tag, recordKeyMap);
                        let val = fromArg(innerType, v.value, recordKeyMap);

                        return #Variant((key, val));
                    };
                };

                Debug.trap("Could not find variant type for '" # debug_show v.tag # "'");
            };

            case (#recursiveReference(ref_id), #variant(v)) {
                let key = getKey(v.tag, recordKeyMap);
                let val = fromArg(#recursiveReference(ref_id), v.value, recordKeyMap);

                return #Variant((key, val));
            };

            case (#recursiveType({ type_ }), value_) {
                fromArg(type_, value_, recordKeyMap);
            };

            case (x) {
                Debug.trap(
                    "
                    Serde Decoding Error from fromArg() fn in Candid/Blob/Decoder.mo
                    Error Log: Could not match '" # debug_show (x) # "' type to any case
                    "
                );
            };
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
