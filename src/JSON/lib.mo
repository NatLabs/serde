import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";

import JSON "mo:json/JSON";

import Candid "../Candid";

module {
    public type JSON = JSON.JSON;
    public type Candid = Candid.Candid;

    public func fromText(rawText : Text) : ?Blob {
        let json = JSON.parse(rawText);

        let candid = switch (json) {
            case (?json) {
                toCandid(json);
            };
            case (_) {
                return null;
            };
        };

        ?Candid.decode(candid);
    };

    func toCandid(json : JSON) : Candid {
        switch (json) {
            case (#Null) #Null;
            case (#Boolean(n)) #Bool(n);
            case (#Number(n)) #Int(n);
            case (#String(n)) #Text(n);
            case (#Array(arr)) {
                let newArr = Array.map(
                    arr,
                    func(n : JSON) : Candid {
                        toCandid(n);
                    },
                );

                #Vector(newArr);
            };
            case (#Object(objs)) {
                let records = Array.map<(Text, JSON), (Text, Candid)>(
                    objs,
                    func((key, val) : (Text, JSON)) : (Text, Candid) {
                        (key, toCandid(val));
                    },
                );

                #Record(records);
            };
        };
    };
};
