/// A representation of the Candid format with variants for all possible types.

import Text "mo:base/Text";

import Encoder "Blob/Encoder";
import Decoder "Blob/Decoder";
import RepIndyHash "Blob/RepIndyHash";

import Parser "Text/Parser";
import ToText "Text/ToText";

import T "Types";
import Utils "../Utils";

module {
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

    public let concatKeys = Utils.concatKeys;

};
