import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Order "mo:base/Order";

/// A representation of the Candid format with variants for all possible types.

import Result "mo:base/Result";
import Prelude "mo:base/Prelude";

import Itertools "mo:itertools/Iter";


import Encoder "Blob/Encoder";
import Decoder "Blob/Decoder";
import Parser "Text/Parser";
import ToText "Text/ToText";

import T "Types";
import Utils "../Utils";


module {
    /// A representation of the Candid format with variants for all possible types.
    public type Candid = T.Candid;
    
    /// Converts a motoko value to a [Candid](#Candid) value
    public let { encode; encodeOne } = Encoder;

    /// Converts a [Candid](#Candid) value to a motoko value
    public let { decode } = Decoder;

    public func fromText(t : Text) : [Candid] {
        Parser.parse(t);
    };

    public let { toText } = ToText;

    public let concatKeys = Utils.concatKeys;


};
