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
import NatX "mo:xtended-numbers/NatX";
import IntX "mo:xtended-numbers/IntX";

import Candid "../Candid";
import CandidTypes "../Candid/Types";

module {
    type JSON = JSON.JSON;
    type Candid = Candid.Candid;

    /// Converts serialized Candid blob to JSON text
    public func toText(blob : Blob, keys : [Text], options: ?CandidTypes.Options) : Text {
        let candid = Candid.decode(blob, keys, options);
        fromCandid(candid[0]);
    };

    /// Convert a Candid value to JSON text
    public func fromCandid(candid : Candid) : Text {
        let json = candidToJSON(candid);

        JSON.show(json);
    };

    func candidToJSON(candid : Candid) : JSON {
        switch (candid) {
            case (#Null) #Null;
            case (#Bool(n)) #Boolean(n);
            case (#Text(n)) #String(n);

            case (#Int(n)) #Number(n);
            case (#Int8(n)) #Number(IntX.from8ToInt(n));
            case (#Int16(n)) #Number(IntX.from16ToInt(n));
            case (#Int32(n)) #Number(IntX.from32ToInt(n));
            case (#Int64(n)) #Number(IntX.from64ToInt(n));

            case (#Nat(n)) #Number(n);
            case (#Nat8(n)) #Number(NatX.from8ToNat(n));
            case (#Nat16(n)) #Number(NatX.from16ToNat(n));
            case (#Nat32(n)) #Number(NatX.from32ToNat(n));
            case (#Nat64(n)) #Number(NatX.from64ToNat(n));

            case (#Float(n)) #Number(Float.toInt(n));

            case (#Option(val)) {
                switch (val) {
                    case (#Null) #Null;
                    case (v) candidToJSON(v);
                };
            };
            case (#Array(arr)) {
                let newArr = Array.map(
                    arr,
                    func(n : Candid) : JSON {
                        candidToJSON(n);
                    },
                );

                #Array(newArr);
            };

            case (#Record(records)) {
                let objs = Array.map<(Text, Candid), (Text, JSON)>(
                    records,
                    func((key, val) : (Text, Candid)) : (Text, JSON) {
                        (key, candidToJSON(val));
                    },
                );

                #Object(objs);
            };

            case (#Variant(variant)) {
                let (key, val) = variant;
                #Object([("#" # key, candidToJSON(val))]);
            };
            
            // #Blob(_), #Empty and #Principal(_) are not supported
            case (_) Prelude.unreachable();
        };
    };
};
