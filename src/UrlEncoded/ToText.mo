import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
import Principal "mo:base/Principal";

import itertools "mo:itertools/Iter";

import Candid "../Candid";
import U "../Utils";
import Utils "../Utils";
import CandidType "../Candid/Types";

module {
    type Candid = Candid.Candid;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<K, V> = Result.Result<K, V>;

    /// Converts a serialized Candid blob to a URL-Encoded string.
    public func toText(blob : Blob, keys : [Text], options: ?CandidType.Options) : Result<Text, Text> {
        let res = Candid.decode(blob, keys, options);
        let #ok(candid) = res else return Utils.send_error(res);
        fromCandid(candid[0]);
    };

    /// Convert a Candid Record to a URL-Encoded string.
    public func fromCandid(candid : Candid) : Result<Text, Text> {

        let records = switch (candid) {
            case (#Record(records) or #Map(records)) records;
            case (_) return #err("invalid type: the value must be a record");
        };

        let pairs = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        for ((key, value) in records.vals()) {
            toKeyValuePairs(pairs, key, value);
        };

        var url_encoding = "";

        let entries = Iter.map(
            pairs.entries(),
            func((key, value) : (Text, Text)) : Text {
                key # "=" # value;
            },
        );

        for (t in entries){
            url_encoding := if (url_encoding == "") {
                t ;
            } else {
                t # "&" # url_encoding;
            };
        };

        #ok(url_encoding);
    };

    func toKeyValuePairs(
        pairs : TrieMap<Text, Text>,
        storedKey : Text,
        candid : Candid,
    ) {
        switch (candid) {
            case (#Array(arr)) {
                for ((i, value) in itertools.enumerate(arr.vals())) {
                    let array_key = storedKey # "[" # Nat.toText(i) # "]";
                    toKeyValuePairs(pairs, array_key, value);
                };
            };

            case (#Record(records) or #Map(records)) {
                for ((key, value) in records.vals()) {
                    let record_key = storedKey # "[" # key # "]";
                    toKeyValuePairs(pairs, record_key, value);
                };
            };

            case (#Variant(key, val)) {
                let variant_key = storedKey # "#" # key;
                toKeyValuePairs(pairs, variant_key, val);
            };
            
            // TODO: convert blob to hex
            case(#Blob(blob)) pairs.put(storedKey, "todo: Blob.toText(blob)");

            case (#Option(p)) toKeyValuePairs(pairs, storedKey, p);
            case (#Text(t)) pairs.put(storedKey, t);
            case (#Principal(p)) pairs.put(storedKey, Principal.toText(p));

            case (#Nat(n)) pairs.put(storedKey, Nat.toText(n));
            case (#Nat8(n)) pairs.put(storedKey, debug_show (n));
            case (#Nat16(n)) pairs.put(storedKey, debug_show (n));
            case (#Nat32(n)) pairs.put(storedKey, Nat32.toText(n));
            case (#Nat64(n)) pairs.put(storedKey, debug_show (n));

            case (#Int(n)) pairs.put(storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int8(n)) pairs.put(storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int16(n)) pairs.put(storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int32(n)) pairs.put(storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int64(n)) pairs.put(storedKey, U.stripStart(debug_show (n), #char '+'));

            case (#Float(n)) pairs.put(storedKey, Float.toText(n));
            case (#Null) pairs.put(storedKey, "null");
            case (#Empty) pairs.put(storedKey, "");

            case (#Bool(b)) pairs.put(storedKey, debug_show (b));

        };
    };
};
