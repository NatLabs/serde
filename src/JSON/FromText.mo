import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Hash "mo:base/Hash";
import Float "mo:base/Float";
import Prelude "mo:base/Prelude";

import JSON "mo:json/JSON";

import Candid "../Candid";
import U "../Utils";
import CandidTypes "../Candid/Types";

module {
    type JSON = JSON.JSON;
    type Candid = Candid.Candid;

    /// Converts JSON text to a serialized Candid blob that can be decoded to motoko values using `from_candid()`
    public func fromText(rawText : Text, options: ?CandidTypes.Options) : Blob {
        let candid = toCandid(rawText);
        Candid.encodeOne(candid, options);
    };

    /// Convert JSON text to a Candid value
    public func toCandid(rawText: Text): Candid {
        let json = JSON.parse(rawText);

        let candid = switch (json) {
            case (?json) jsonToCandid(json);
            case (_) Debug.trap("Failed to parse JSON");
        };

        candid
    };

    func jsonToCandid(json : JSON) : Candid {
        switch (json) {
            case (#Null) #Null;
            case (#Boolean(n)) #Bool(n);
            case (#Number(n)) {
                if (n < 0) {
                    return #Int(n);
                };

                #Nat(Int.abs(n));
            };
            case (#String(n)) #Text(n);
            case (#Array(arr)) {
                let newArr = Array.map(
                    arr,
                    func(n : JSON) : Candid {
                        jsonToCandid(n);
                    },
                );

                #Array(newArr);
            };
            case (#Object(objs)) {

                if (objs.size() == 1) {
                    let (key, val) = objs[0];

                    if (Text.startsWith(key, #text "#")) {
                        let tag = U.stripStart(key, #text "#");
                        return #Variant(tag, jsonToCandid(val));
                    };
                };

                let records = Array.map<(Text, JSON), (Text, Candid)>(
                    objs,
                    func((key, val) : (Text, JSON)) : (Text, Candid) {
                        (key, jsonToCandid(val));
                    },
                );

                #Record(records);
            };
        };
    };
};
