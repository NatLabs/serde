/// A representation of the Candid format with variants for all possible types.

import Array "mo:base/Array";
import Text "mo:base/Text";

import Encoder "Blob/Encoder";
import Decoder "Blob/Decoder";
import RepIndyHash "Blob/RepIndyHash";
import CandidUtils "Blob/CandidUtils";

import Parser "Text/Parser";
import ToText "Text/ToText";

import T "Types";
import Utils "../Utils";
import ICRC3Value "ICRC3Value";

import Map "mo:map/Map";

module {
    let { thash } = Map;

    /// A representation of the Candid format with variants for all possible types.
    public type Candid = T.Candid;
    public type Options = T.Options;
    public let defaultOptions = T.defaultOptions;

    public type CandidType = T.CandidType;

    /// Converts a motoko value to a [Candid](#Candid) value
    public let { encode; encodeOne } = Encoder;

    public let repIndyHash = RepIndyHash.hash;

    /// Converts a [Candid](#Candid) value to a motoko value
    public let { decode } = Decoder;

    public func fromText(t : Text) : [Candid] {
        Parser.parse(t);
    };

    public let { toText } = ToText;

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

};
