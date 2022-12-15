import Array "mo:base/Array";
import Debug "mo:base/Debug";
/// A representation of the Candid format with variants for all possible types.

import Result "mo:base/Result";
import Prelude "mo:base/Prelude";

import Encoder "Encoder";
import Decoder "Decoder";

import T "Types";

module {
    /// A representation of the Candid format with variants for all possible types.
    public type Candid = T.Candid;

    /// Converts a motoko value to a [Candid](#Candid) value
    public let { encode } = Encoder;

    /// Converts a [Candid](#Candid) value to a motoko value
    public let { decode } = Decoder;

};
