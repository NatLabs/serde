import Result "mo:core/Result";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Text "mo:core/Text";
import PureMap "mo:core/pure/Map";
import Iter "mo:core/Iter";
import Float "mo:core/Float";
import Principal "mo:core/Principal";
import Debug "mo:core/Debug";

import itertools "mo:itertools@0.2.2/Iter";

import Candid "../Candid";
import U "../Utils";
import Utils "../Utils";
import CandidType "../Candid/Types";

module {
    type Candid = Candid.Candid;
    type Map<K, V> = PureMap.Map<K, V>;
    type Result<K, V> = Result.Result<K, V>;

    /// Converts a serialized Candid blob to a URL-Encoded string.
    public func toText(blob : Blob, keys : [Text], options : ?CandidType.Options) : Result<Text, Text> {
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

        var pairs = PureMap.empty<Text, Text>();

        for ((key, value) in records.vals()) {
            pairs := toKeyValuePairs(pairs, key, value);
        };

        var url_encoding = "";

        let entries = Iter.map(
            PureMap.entries(pairs),
            func((key, value) : (Text, Text)) : Text {
                key # "=" # value;
            },
        );

        for (t in entries) {
            url_encoding := if (url_encoding == "") {
                t;
            } else {
                t # "&" # url_encoding;
            };
        };

        #ok(url_encoding);
    };

    func toKeyValuePairs(
        pairs : Map<Text, Text>,
        storedKey : Text,
        candid : Candid,
    ) : Map<Text, Text> {
        switch (candid) {
            case (#Array(arr)) {
                var result = pairs;
                for ((i, value) in itertools.enumerate(arr.vals())) {
                    let array_key = storedKey # "[" # Nat.toText(i) # "]";
                    result := toKeyValuePairs(result, array_key, value);
                };
                result;
            };

            case (#Record(records) or #Map(records)) {
                var result = pairs;
                for ((key, value) in records.vals()) {
                    let record_key = storedKey # "[" # key # "]";
                    result := toKeyValuePairs(result, record_key, value);
                };
                result;
            };

            case (#Variant(key, val)) {
                let variant_key = storedKey # "#" # key;
                toKeyValuePairs(pairs, variant_key, val);
            };

            // TODO: convert blob to hex
            // case (#Blob(blob)) PureMap.add(pairs, Text.compare, storedKey, "todo: Blob.toText(blob)");

            case (#Option(p)) toKeyValuePairs(pairs, storedKey, p);
            case (#Text(t)) PureMap.add(pairs, Text.compare, storedKey, t);
            case (#Principal(p)) PureMap.add(pairs, Text.compare, storedKey, Principal.toText(p));

            case (#Nat(n)) PureMap.add(pairs, Text.compare, storedKey, Nat.toText(n));
            case (#Nat8(n)) PureMap.add(pairs, Text.compare, storedKey, debug_show (n));
            case (#Nat16(n)) PureMap.add(pairs, Text.compare, storedKey, debug_show (n));
            case (#Nat32(n)) PureMap.add(pairs, Text.compare, storedKey, Nat32.toText(n));
            case (#Nat64(n)) PureMap.add(pairs, Text.compare, storedKey, debug_show (n));

            case (#Int(n)) PureMap.add(pairs, Text.compare, storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int8(n)) PureMap.add(pairs, Text.compare, storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int16(n)) PureMap.add(pairs, Text.compare, storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int32(n)) PureMap.add(pairs, Text.compare, storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int64(n)) PureMap.add(pairs, Text.compare, storedKey, U.stripStart(debug_show (n), #char '+'));

            case (#Float(n)) PureMap.add(pairs, Text.compare, storedKey, Float.toText(n));
            case (#Null) PureMap.add(pairs, Text.compare, storedKey, "null");
            case (#Empty) PureMap.add(pairs, Text.compare, storedKey, "");

            case (#Bool(b)) PureMap.add(pairs, Text.compare, storedKey, debug_show (b));

            case (_) Debug.trap(debug_show candid # " is not supported by URL-Encoded");

        };
    };
};
