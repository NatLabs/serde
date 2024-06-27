import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Option "mo:base/Option";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

import CBOR_Value "mo:cbor/Value";
import CBOR_Encoder "mo:cbor/Encoder";
import CBOR_Decoder "mo:cbor/Decoder";
import NatX "mo:xtended-numbers/NatX";
import FloatX "mo:xtended-numbers/FloatX";

import Candid "../Candid";
import CandidType "../Candid/Types";

import Utils "../Utils";

module {
    public type Candid = CandidType.Candid;
    type Result<A, B> = Result.Result<A, B>;
    type CBOR = CBOR_Value.Value;

    public type Options = CandidType.Options;
    
    /// Converts serialized Candid blob to CBOR blob
    public func encode(blob : Blob, keys : [Text], options: ?Options) : Result<Blob, Text> {
        let decoded_res = Candid.decode(blob, keys, options);
        let #ok(candid) = decoded_res else return Utils.send_error(decoded_res);

        let json_res = fromCandid(candid[0], Option.get(options, CandidType.defaultOptions));
        let #ok(json) = json_res else return Utils.send_error(json_res);
        #ok(json);
    };

    /// Convert a Candid value to CBOR blob
    public func fromCandid(candid : Candid, options: CandidType.Options) : Result<Blob, Text> {
        let res = transpile_candid_to_cbor(candid, options);
        let #ok(transpiled_cbor) = res else return Utils.send_error(res);

        let cbor_with_self_describe_tag = #majorType6({ tag = 55799 : Nat64; value = transpiled_cbor; });

        switch(CBOR_Encoder.encode(cbor_with_self_describe_tag)){
            case(#ok(encoded_cbor)){ #ok (Blob.fromArray(encoded_cbor))};
            case(#err(#invalidValue(errMsg))){ #err("Invalid value error while encoding CBOR: " # errMsg) };
        };
    };

    func transpile_candid_to_cbor(candid : Candid, options: CandidType.Options) : Result<CBOR, Text> {
        let transpiled_cbor : CBOR = switch(candid){
            case (#Empty) #majorType7(#_undefined);
            case (#Null) #majorType7(#_null);
            case (#Bool(n)) #majorType7(#bool(n));
            case (#Float(n)) #majorType7(#float(FloatX.fromFloat(n, #f64)));

            case (#Nat8(n)) #majorType7(#integer(n));
            case (#Nat16(n)) #majorType0(NatX.from16To64(n));
            case (#Nat32(n)) #majorType0(NatX.from32To64(n));
            case (#Nat64(n)) #majorType0(n);
            case (#Nat(n)) #majorType0(Nat64.fromNat(n));

            case (#Int8(n)) #majorType1(Int8.toInt(n));
            case (#Int16(n)) #majorType1(Int16.toInt(n));
            case (#Int32(n)) #majorType1(Int32.toInt(n));
            case (#Int64(n)) #majorType1(Int64.toInt(n));
            case (#Int(n)) #majorType1(n);

            case (#Blob(blob)) #majorType2(Blob.toArray(blob));
            case (#Text(n)) #majorType3(n);
            case (#Array(arr)) {
                let buffer = Buffer.Buffer<CBOR>(arr.size());

                for (item in arr.vals()){
                    let res = transpile_candid_to_cbor(item, options);
                    let #ok(cbor_val) = res else return Utils.send_error(res);
                    buffer.add(cbor_val);
                };

                #majorType4(Buffer.toArray(buffer));
            };
            case (#Record(records) or #Map(records)) {
                let newRecords = Buffer.Buffer<(CBOR, CBOR)>(records.size());

                for ((key, val) in records.vals()){
                    let res = transpile_candid_to_cbor(val, options);
                    let #ok(cbor_val) = res else return Utils.send_error(res);
                    newRecords.add((#majorType3(key), cbor_val));
                };

                #majorType5(Buffer.toArray(newRecords));
            };

            // Candid can make variables optional, when it is decoded using 
            // `from_candid` if its specified in the type defination
            // This features allow us to handle optional values when decoding CBOR
            // 
            // check out "CBOR Tests.options" in the tests folder to see how this in action
            case (#Option(option)) {
                let res = transpile_candid_to_cbor(option, options);
                let #ok(cbor_val) = res else return Utils.send_error(res);
                cbor_val
            };

            case (#Principal(p)) #majorType2(Blob.toArray(Principal.toBlob(p)));

            case (#Variant(_)) {
                return #err("#Variant(_) is not supported in this implementation of CBOR");
            };
        };

        #ok(transpiled_cbor);
    };

    public func decode(blob: Blob, options: ?Options): Result<Blob, Text> {
        let candid_res = toCandid(blob, Option.get(options, CandidType.defaultOptions));
        let #ok(candid) = candid_res else return Utils.send_error(candid_res);
        Candid.encodeOne(candid, options);
    };

    public func toCandid(blob: Blob, options: CandidType.Options): Result<Candid, Text> {
        let cbor_res = CBOR_Decoder.decode(blob);
        
        let candid_res = switch (cbor_res) {
            case (#ok(cbor)) {
                let #majorType6({ tag = 55799; value }) = cbor else return transpile_cbor_to_candid(cbor, options);
                transpile_cbor_to_candid(value, options);
            };
            case (#err(cbor_error)) {
                switch(cbor_error){
                    case (#unexpectedBreak){ return #err("Error decoding CBOR: Unexpected break") };
                    case (#unexpectedEndOfBytes) { return #err("Error decoding CBOR: Unexpected end of bytes") };
                    case (#invalid(errMsg)) { return #err("Invalid CBOR: " # errMsg) };
                };
            };
        };
        
        let #ok(candid) = candid_res else return Utils.send_error(candid_res);
        #ok(candid);
    };

    public func transpile_cbor_to_candid(cbor: CBOR, options: CandidType.Options) : Result<Candid, Text>{
        let transpiled_candid = switch(cbor){
            case (#majorType0(n)) #Nat(Nat64.toNat(n));
            case (#majorType1(n)) #Int(n);
            case (#majorType2(n)) #Blob(Blob.fromArray(n));
            case (#majorType3(n)) #Text(n);
            case (#majorType4(arr)) {
                let buffer = Buffer.Buffer<Candid>(arr.size());
                for (item in arr.vals()){
                    let res = transpile_cbor_to_candid(item, options);
                    let #ok(candid_val) = res else return Utils.send_error(res);
                    buffer.add(candid_val);
                };
                #Array(Buffer.toArray(buffer));
            };
            case (#majorType5(records)) {
                let buffer = Buffer.Buffer<(Text, Candid)>(records.size());
                for ((cbor_text, val) in records.vals()){
                    let #majorType3(key) = cbor_text else return #err("Error decoding CBOR: Unexpected key type");

                    let res = transpile_cbor_to_candid(val, options);
                    let #ok(candid_val) = res else return Utils.send_error(res);
                    buffer.add((key, candid_val));
                };

                if (options.use_icrc_3_value_type){
                    #Map(Buffer.toArray(buffer));
                } else {
                    #Record(Buffer.toArray(buffer));
                };
            };
            case (#majorType7(#_undefined)) #Empty;
            case (#majorType7(#_null)) #Null;
            case (#majorType7(#bool(n))) #Bool(n);
            case (#majorType7(#integer(n))) #Nat8(n);
            case (#majorType7(#float(n))) #Float(FloatX.toFloat(n));

            case (#majorType7(#_break)) {
                return #err("Error decoding CBOR: #_break is not supported");
            };
            case (#majorType6(tagged_cbor)) {
                return #err("Error decoding CBOR: Tagged values are not supported");
            };
        };

        #ok(transpiled_candid);
    };
}