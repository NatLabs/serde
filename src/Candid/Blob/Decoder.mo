import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
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
import Itertools "mo:itertools/Iter";

import T "../Types";
import U "../../Utils";
import Utils "../../Utils";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;
    type Iter<A> = Iter.Iter<A>;
    type Result<A, B> = Result.Result<A, B>;

    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    /// Decodes a blob encoded in the candid format into a list of the [Candid](./Types.mo#Candid) type in motoko
    ///
    /// ### Inputs
    /// - **blob** -  A blob encoded in the candid format
    /// - **record_keys** - The record keys to use when decoding a record.
    /// - **options** - An optional arguement to specify options for decoding.

    public func decode(blob : Blob, record_keys : [Text], options : ?T.Options) : Result<[Candid], Text> {
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

        let decoded = Decoder.decode(blob);

        let ?(args) = decoded else return #err("Candid Error: Failed to decode candid blob");

        fromArgs(args, recordKeyMap);
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

    public func fromArgs(args : [Arg], recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Result<[Candid], Text> {
        let buffer = Buffer.Buffer<Candid>(args.size());

        for (arg in args.vals()) {
            let res = fromArg(arg.type_, arg.value, recordKeyMap);
            let #ok(val) = res else return Utils.send_error(res);
            buffer.add(val);
        };

        #ok(Buffer.toArray(buffer));
    };

    func fromArg(type_ : Type, val : Value, recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Result<Candid, Text> {
        let result : Candid = switch (type_, val) {
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
                let res = fromArg(innerType, optVal, recordKeyMap);
                let #ok(val) = res else return Utils.send_error(res);
                #Option(val);
            };

            case (#recursiveReference(ref_id), #opt(optVal)){
                let res = fromArg(#recursiveReference(ref_id), optVal, recordKeyMap);
                let #ok(val) = res else return Utils.send_error(res);
                #Option(val);
            };

            // #vector
            // #vector(#nat8) -> blob
            case (#vector(#nat8), #vector(arr)) {
                let buffer = Buffer.Buffer<Nat8>(arr.size());

                for ((i, elem) in Itertools.enumerate(arr.vals())){
                    let #nat8(val) = elem else return #err("Expected #nat8 in #vector but found '" # debug_show(elem)  # "' at index '" # debug_show i # "' of #vector(" # debug_show arr # ")");
                    buffer.add(val);
                };

                let blob = Blob.fromArray(Buffer.toArray(buffer));
                #Blob(blob);
            };
            case (#vector(innerType), #vector(arr)) {
                let buffer = Buffer.Buffer<Candid>(arr.size());

                for (elem in arr.vals()){
                    let res = fromArg(innerType, elem, recordKeyMap);
                    let #ok(val) = res else return Utils.send_error(res);
                    buffer.add(val);
                };

                let newArr = Buffer.toArray(buffer);

                #Array(newArr);
            };
            case (#recursiveReference(ref_id), #vector(arr)) {

                let buffer = Buffer.Buffer<Candid>(arr.size());

                for (elem in arr.vals()){
                    let res = fromArg(#recursiveReference(ref_id), elem, recordKeyMap);
                    let #ok(val) = res else return Utils.send_error(res);
                    buffer.add(val);
                };

                let newArr = Buffer.toArray(buffer);

                #Array(newArr);
            };

            // #record
            case (#record(recordTypes), #record(records)) {
                let newRecords = Buffer.Buffer<KeyValuePair>(records.size());

                let zippedTypesAndValues = Itertools.zip(recordTypes.vals(), records.vals());

                for ((record_type, record_val) in zippedTypesAndValues) {
                    let { type_ = innerType } = record_type;
                    let { tag; value } = record_val;

                    let key = getKey(tag, recordKeyMap);
                    let res = fromArg(innerType, value, recordKeyMap);
                    let #ok(val) = res else return Utils.send_error(res);

                    newRecords.add((key, val));
                };

                newRecords.sort(U.cmpRecords);

                #Record(Buffer.toArray(newRecords));
            };

            case (#recursiveReference(ref_id), #record(records)) {

                let newRecords = Buffer.Buffer<KeyValuePair>(records.size());

                for (record in records.vals()){
                    let { tag; value } = record;

                    let key = getKey(tag, recordKeyMap);
                    let res = fromArg(#recursiveReference(ref_id), value, recordKeyMap);
                    let #ok(val) = res else return Utils.send_error(res);

                    newRecords.add((key, val));
                };

                newRecords.sort(U.cmpRecords);

                #Record(Buffer.toArray(newRecords));
            };

            case ( #variant(variantTypes), #variant(v)) {

                for ({ tag; type_ = innerType } in variantTypes.vals()) {
                    if (tag == v.tag) {
                        let key = getKey(tag, recordKeyMap);
                        let res = fromArg(innerType, v.value, recordKeyMap);

                        let #ok(val) = res else return Utils.send_error(res);

                        return #ok(#Variant((key, val)));
                    };
                };

                return #err("Could not find variant type for '" # debug_show #variant(v) # "' in " # debug_show #variant(variantTypes));
            };

            case (#recursiveReference(ref_id), #variant(v)) {
                let key = getKey(v.tag, recordKeyMap);
                let res = fromArg(#recursiveReference(ref_id), v.value, recordKeyMap);

                let #ok(val) = res else return Utils.send_error(res);

                #Variant((key, val));
            };

            case (#recursiveType({ type_ }), value_) {
                let res = fromArg(type_, value_, recordKeyMap);
                let #ok(val) = res else return Utils.send_error(res);
                val;
            };

            case (x) {
                return #err(
                    "\nSerde Decoding Error from fromArg() fn in Candid/Blob/Decoder.mo\n\tError Log: Could not match '" # debug_show (x) # "' type to any case"
                );
            };
        };

        #ok(result);
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
