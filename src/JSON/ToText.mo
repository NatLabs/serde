import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Text "mo:base/Text";

import JSON "mo:json-float/JSON";
import NatX "mo:xtended-numbers/NatX";
import IntX "mo:xtended-numbers/IntX";

import Candid "../Candid";
import CandidType "../Candid/Types";
import Utils "../Utils";

module {
    type JSON = JSON.JSON;
    type Candid = Candid.Candid;
    type Result<A, B> = Result.Result<A, B>;

    /// Converts serialized Candid blob to JSON text
    public func toText(blob : Blob, keys : [Text], options: ?CandidType.Options) : Result<Text, Text> {
        let decoded_res = Candid.decode(blob, keys, options);
        let #ok(candid) = decoded_res else return Utils.send_error(decoded_res);

        let json_res = fromCandid(candid[0]);
        let #ok(json) = json_res else return Utils.send_error(json_res);
        #ok(json);
    };

    /// Convert a Candid value to JSON text
    public func fromCandid(candid : Candid) : Result<Text, Text> {
        let res = candidToJSON(candid);
        let #ok(json) = res else return Utils.send_error(res);

        #ok(JSON.show(json));
    };

    func candidToJSON(candid : Candid) : Result<JSON, Text> {
        let json : JSON = switch (candid) {
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

            case (#Float(n)) #Float(n);

            case (#Option(val)) {
                let res = switch (val) {
                    case (#Null) return #ok(#Null);
                    case (v) candidToJSON(v);
                };

                let #ok(optional_val) = res else return Utils.send_error(res);
                optional_val;
            };
            case (#Array(arr)) {
                let newArr = Buffer.Buffer<JSON>(arr.size());

                for (item in arr.vals()){
                    let res = candidToJSON(item);
                    let #ok(json) = res else return Utils.send_error(res);
                    newArr.add(json);
                };

                #Array(Buffer.toArray(newArr));
            };

            case (#Record(records) or #Map(records)) {
                let newRecords = Buffer.Buffer<(Text, JSON)>(records.size());

                for ((key, val) in records.vals()){
                    let res = candidToJSON(val);
                    let #ok(json) = res else return Utils.send_error(res);
                    newRecords.add((key, json));
                };

                #Object(Buffer.toArray(newRecords));
            };

            case (#Variant(variant)) {
                let (key, val) = variant;
                let res = candidToJSON(val);
                let #ok(json_val) = res else return Utils.send_error(res);

                #Object([("#" # key, json_val)]);
            };
            
            case (#Blob(_)){
                return #err("#Blob(_) is not supported by JSON");
            };

            case (#Empty){
                return #err("#Empty is not supported by JSON");
            };

            case (#Principal(_)){
                return #err("#Principal(_) is not supported by JSON");
            };
        };

        #ok(json)
    };
};
