/// A module for converting between Motoko values and Url-Encoded `Text`.

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Float "mo:base/Float";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";

import itertools "mo:itertools/Iter";

import Candid "../Candid";
import FromText "./FromText";
import ToText "./ToText";

module {
    /// Converts a Url-Encoded `Text` to a motoko value encoded as a `Blob`.
    public let { fromText } = FromText;

    /// Converts a motoko value encoded as a `Blob` to a Url-Encoded `Text`.
    public let { toText } = ToText;
};
