import Result "mo:core@2.4/Result";
import Nat "mo:core@2.4/Nat";
import Nat32 "mo:core@2.4/Nat32";
import Text "mo:core@2.4/Text";
import Buffer "mo:base/Buffer";
import Map "mo:map@9.0/Map";
import Float "mo:core@2.4/Float";
import Principal "mo:core@2.4/Principal";
import Debug "mo:core@2.4/Debug";
import Runtime "mo:core@2.4/Runtime";

import itertools "mo:itertools@0.2.2/Iter";

import Candid "../Candid";
import U "../Utils";
import Utils "../Utils";
import CandidType "../Candid/Types";

module {
    type Candid = Candid.Candid;
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

        let pairsMap = Map.new<Text, Text>();
        let pairsOrder = Buffer.Buffer<Text>(16);

        for ((key, value) in records.vals()) {
            toKeyValuePairs(pairsMap, pairsOrder, key, value);
        };

        var url_encoding = "";

        for (key in pairsOrder.vals()) {
            let value = switch (Map.get(pairsMap, Map.thash, key)) {
                case (?v) v;
                case (null) "";
            };
            let t = key # "=" # value;
            url_encoding := if (url_encoding == "") {
                t;
            } else {
                url_encoding # "&" # t;
            };
        };

        #ok(url_encoding);
    };

    func toKeyValuePairs(
        pairsMap : Map.Map<Text, Text>,
        pairsOrder : Buffer.Buffer<Text>,
        storedKey : Text,
        candid : Candid,
    ) {
        func set(key : Text, value : Text) {
            if (Map.get(pairsMap, Map.thash, key) == null) {
                pairsOrder.add(key);
            };
            Map.set(pairsMap, Map.thash, key, value);
        };
        switch (candid) {
            case (#Array(arr)) {
                for ((i, value) in itertools.enumerate(arr.vals())) {
                    let array_key = storedKey # "[" # Nat.toText(i) # "]";
                    toKeyValuePairs(pairsMap, pairsOrder, array_key, value);
                };
            };

            case (#Record(records) or #Map(records)) {
                for ((key, value) in records.vals()) {
                    let record_key = storedKey # "[" # key # "]";
                    toKeyValuePairs(pairsMap, pairsOrder, record_key, value);
                };
            };

            case (#Variant(key, val)) {
                let variant_key = storedKey # "#" # key;
                toKeyValuePairs(pairsMap, pairsOrder, variant_key, val);
            };

            // TODO: convert blob to hex
            // case (#Blob(blob)) set(storedKey, "todo: Blob.toText(blob)");

            case (#Option(p)) toKeyValuePairs(pairsMap, pairsOrder, storedKey, p);
            case (#Text(t)) set(storedKey, t);
            case (#Principal(p)) set(storedKey, Principal.toText(p));

            case (#Nat(n)) set(storedKey, Nat.toText(n));
            case (#Nat8(n)) set(storedKey, debug_show (n));
            case (#Nat16(n)) set(storedKey, debug_show (n));
            case (#Nat32(n)) set(storedKey, Nat32.toText(n));
            case (#Nat64(n)) set(storedKey, debug_show (n));

            case (#Int(n)) set(storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int8(n)) set(storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int16(n)) set(storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int32(n)) set(storedKey, U.stripStart(debug_show (n), #char '+'));
            case (#Int64(n)) set(storedKey, U.stripStart(debug_show (n), #char '+'));

            case (#Float(n)) set(storedKey, Float.toText(n));
            case (#Null) set(storedKey, "null");
            case (#Empty) set(storedKey, "");

            case (#Bool(b)) set(storedKey, debug_show (b));

            case (_) Runtime.trap(debug_show candid # " is not supported by URL-Encoded");

        };
    };
};
