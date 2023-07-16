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

import Candid "../Candid";
import FromText "./FromText";
import ToText "./ToText";

module {
    public let { fromText; toCandid } = FromText;

    public let { toText; fromCandid } = ToText;

};
