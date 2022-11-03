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
import NatX "mo:xtendedNumbers/NatX";
import IntX "mo:xtendedNumbers/IntX";

import Candid "../Candid";

module {
    // ToDo
    public func toText(blob : Blob, keys : [Text]) : Text {
        let candid = Candid.encode(blob, keys);

        // switch (candid) {
        //     case (#Record(records)) {
        //         Array.map(records)
        //     };
        //     case (_) Prelude.unreachable();
        // };
        "";
    };
};
