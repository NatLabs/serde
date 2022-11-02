import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Prelude "mo:base/Prelude";

import Encoder "Encoder";
import Decoder "Decoder";

import T "Types";

module {
    public type Candid = T.Candid;

    public let { encode } = Encoder;
    public let { decode } = Decoder;
};
