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

module {
    type Candid = Candid.Candid;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    public func toText(blob : Blob, keys : [Text]) : Text {
        let candid = Candid.encode(blob, keys);
        let pairs : TrieMap<Text, Text> = TrieMap.TrieMap(Text.equal, Text.hash);

        switch (candid) {
            case (#Record(records)) {
                for ((key, value) in records.vals()) {
                    toKeyValuePairs(pairs, key, value);
                };
            };
            case (_) Debug.trap("invalid type: the value must be a record");
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

    func cmpKeys((a, _) : (Text, Text), (b, _) : (Text, Text)) : Order.Order {
        Text.compare(a, b);
    };

    func toKeyValuePairs(
        pairs : TrieMap<Text, Text>,
        storedKey : Text,
        candid : Candid,
    ) {
        switch (candid) {
            case (#Record(records)) {
                for ((key, value) in records.vals()) {
                    toKeyValuePairs(pairs, storedKey # "[" # key # "]", value);
                };
            };
            case (#Array(arr)) {
                for ((i, value) in itertools.enumerate(arr.vals())) {
                    toKeyValuePairs(pairs, storedKey # "[" # Nat.toText(i) # "]", value);
                };
            };

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

            case (#Variant(_)) Debug.trap("invalid type: variant is not supported");
        };
    };
};
