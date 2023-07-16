import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Float "mo:base/Float";
import Order "mo:base/Order";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Prelude "mo:base/Prelude";

import itertools "mo:itertools/Iter";

import Candid "../Candid";
import U "../Utils";
import CandidTypes "../Candid/Types";

module {
    type Candid = Candid.Candid;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    /// Converts a serialized Candid blob to a URL-Encoded string.
    public func toText(blob : Blob, keys : [Text], options: ?CandidTypes.Options) : Text {
        let candid = Candid.decode(blob, keys, options);
        fromCandid(candid[0]);
    };

    /// Convert a Candid Record to a URL-Encoded string.
    public func fromCandid(candid : Candid) : Text {

        let records = switch (candid) {
            case (#Record(records)) records;
            case (_) Debug.trap("invalid type: the value must be a record");
        };

        let pairs = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        for ((key, value) in records.vals()) {
            toKeyValuePairs(pairs, key, value);
        };

        Text.join(
            "&",
            Iter.map(
                pairs.entries(),
                func((key, value) : (Text, Text)) : Text {
                    key # "=" # value;
                },
            ),
        );
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

            case (#Record(records)) {
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
