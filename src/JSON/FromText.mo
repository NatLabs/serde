import Array "mo:base@0.14.14/Array";
import Result "mo:base@0.14.14/Result";
import Text "mo:base@0.14.14/Text";
import Int "mo:base@0.14.14/Int";

import JSON "../../submodules/json.mo/src/JSON";

import Candid "../Candid";
import U "../Utils";
import CandidType "../Candid/Types";
import Utils "../Utils";

module {
    type JSON = JSON.JSON;
    type Candid = Candid.Candid;
    type Result<A, B> = Result.Result<A, B>;

    /// Converts JSON text to a serialized Candid blob that can be decoded to motoko values using `from_candid()`
    public func fromText(rawText : Text, options : ?CandidType.Options) : Result<Blob, Text> {
        let candid_res = toCandid(rawText);
        let #ok(candid) = candid_res else return Utils.send_error(candid_res);
        Candid.encodeOne(candid, options);
    };

    /// Convert JSON text to a Candid value
    public func toCandid(rawText : Text) : Result<Candid, Text> {
        let json = JSON.parse(rawText);

        switch (json) {
            case (?json) #ok(jsonToCandid(json));
            case (_) #err("Failed to parse JSON text");
        };
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
            case (#Float(n)) #Float(n);
            case (#String(n)) #Text(Text.replace(n, #text("\\\""), ("\"")));
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
