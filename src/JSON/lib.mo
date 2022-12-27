/// A module for converting between JSON and Motoko values.

import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Float "mo:base/Float";
import Prelude "mo:base/Prelude";

import JSON "mo:json/JSON";

import Candid "../Candid";
import FromText "FromText";
import ToText "ToText";

module {
    public type JSON = JSON.JSON;

    public let { fromText; toCandid } = FromText;

    public let { toText; fromCandid } = ToText;
};
