/// A representation of the Candid format with variants for all possible types.

import Array "mo:core@2.4/Array";
import Text "mo:core@2.4/Text";
import Map "mo:map@9.0/Map";

import CandidEncoder "Blob/Encoder";
import CandidDecoder "Blob/Decoder";
import RepIndyHash "Blob/RepIndyHash";
import CandidUtilsModule "Blob/CandidUtils";
import TypedSerializerModule "Blob/TypedSerializer";

import Parser "Text/Parser";
import ToText "Text/ToText";

import T "Types";
import Utils "../Utils";
import ICRC3Value "ICRC3Value";

module {
    let { thash } = Map;

    /// A representation of the Candid format with variants for all possible types.
    public type Candid = T.Candid;
    public type Options = T.Options;
    public let defaultOptions = T.defaultOptions;

    public let TypedSerializer = TypedSerializerModule;
    public type TypedSerializer = TypedSerializerModule.TypedSerializer;

    public type CandidType = T.CandidType;

    /// Converts a motoko value to a [Candid](#Candid) value
    public let { encode; encodeOne } = CandidEncoder;

    public let repIndyHash = RepIndyHash.hash;

    /// Converts a [Candid](#Candid) value to a motoko value
    public let { decode; decodeOne } = CandidDecoder;

    public let Encoder = CandidEncoder;
    public let Decoder = CandidDecoder;

    public func fromText(t : Text) : [Candid] {
        Parser.parse(t);
    };

    public let { toText } = ToText; 

    public let CandidUtils = CandidUtilsModule;

    /// Formats a user provided Candid type
    /// It is required to format the Candid type before passing it as an option to the Candid encoder/decoder
    ///
    /// Additionally, all fields that have a name mapping added as a 'renameKeys' option should add the mapping to the function or rename the keys in the Candid type before passing it to the encoder/decoder
    /// Failure to do so will result in unexpected behavior
    public func formatCandidType(c : [CandidType], opt_rename_keys : ?[(Text, Text)]) : [CandidType] {
        let renaming_map = Map.new<Text, Text>();

        switch (opt_rename_keys) {
            case (?rename_keys) {
                for ((prev, new) in rename_keys.vals()) {
                    ignore Map.put(renaming_map, thash, prev, new);
                };
            };
            case (_) {};
        };

        Array.map(
            c,
            func(c : CandidType) : CandidType {
                CandidUtils.format_candid_type(c, renaming_map);
            },
        );

    };

    public func sortCandidType(c : [CandidType]) : [CandidType] {
        Array.map(
            c,
            func(c : CandidType) : CandidType {
                CandidUtils.sort_candid_type(c);
            },
        );
    };

    public let concatKeys = Utils.concatKeys;

    /// Converts an array of ICRC3Value values to [Candid](#Candid) values
    public func fromICRC3Value(icrc3_values : [T.ICRC3Value]) : [Candid] {
        ICRC3Value.fromICRC3Value(icrc3_values);
    };

    /// Converts an array of [Candid](#Candid) values to ICRC3Value values
    public func toICRC3Value(candid_values : [Candid]) : [T.ICRC3Value] {
        ICRC3Value.toICRC3Value(candid_values);
    };

    public type ICRC3Value = T.ICRC3Value;

    /// Compares two Candid values for equality.
    /// `#Null` and `#Option(#Null)` are considered equal.
    public func equal(a : Candid, b : Candid) : Bool {
        switch (a, b) {
            // interchangeable: #Null == #Option(#Null)
            case (#Null, #Option(#Null)) true;
            case (#Option(#Null), #Null) true;

            case (#Int(x), #Int(y)) x == y;
            case (#Int8(x), #Int8(y)) x == y;
            case (#Int16(x), #Int16(y)) x == y;
            case (#Int32(x), #Int32(y)) x == y;
            case (#Int64(x), #Int64(y)) x == y;
            case (#Nat(x), #Nat(y)) x == y;
            case (#Nat8(x), #Nat8(y)) x == y;
            case (#Nat16(x), #Nat16(y)) x == y;
            case (#Nat32(x), #Nat32(y)) x == y;
            case (#Nat64(x), #Nat64(y)) x == y;
            case (#Bool(x), #Bool(y)) x == y;
            case (#Float(x), #Float(y)) x == y;
            case (#Text(x), #Text(y)) x == y;
            case (#Blob(x), #Blob(y)) x == y;
            case (#Null, #Null) true;
            case (#Empty, #Empty) true;
            case (#Principal(x), #Principal(y)) x == y;
            case (#Option(x), #Option(y)) equal(x, y);
            case (#Array(xs), #Array(ys)) {
                if (xs.size() != ys.size()) return false;
                var i = 0;
                while (i < xs.size()) {
                    if (not equal(xs[i], ys[i])) return false;
                    i += 1;
                };
                true;
            };
            case (#Record(xs) or #Map(xs), #Record(ys) or #Map(ys)) {
                if (xs.size() != ys.size()) return false;
                var i = 0;
                while (i < xs.size()) {
                    if (xs[i].0 != ys[i].0) return false;
                    if (not equal(xs[i].1, ys[i].1)) return false;
                    i += 1;
                };
                true;
            };
            case (#Tuple(xs), #Tuple(ys)) {
                if (xs.size() != ys.size()) return false;
                var i = 0;
                while (i < xs.size()) {
                    if (not equal(xs[i], ys[i])) return false;
                    i += 1;
                };
                true;
            };
            case (#Variant((k1, v1)), #Variant((k2, v2))) {
                k1 == k2 and equal(v1, v2)
            };
            case (_) false;
        };
    };

};
