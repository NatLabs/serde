import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Prelude "mo:base/Prelude";

import Encoder "mo:motoko_candid/Encoder";
import Decoder "mo:motoko_candid/Decoder";
import Arg "mo:motoko_candid/Arg";
import Value "mo:motoko_candid/Value";
import Type "mo:motoko_candid/Type";

import T "Types";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;

    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    public func decode(candid : Candid) : Blob {
        let args = toArgs(candid);
        Encoder.encode(args);
    };

    func toArgs(candid : Candid) : [Arg] {
        let arg : Arg = {
            _type = toArgType(candid);
            value = toArgValue(candid);
        };

        [arg];
    };

    func toArgType(candid : Candid) : Type {
        switch (candid) {
            case (#Nat(_)) #Nat;
            case (#Nat8(_)) #Nat8;
            case (#Nat16(_)) #Nat16;
            case (#Nat32(_)) #Nat32;
            case (#Nat64(_)) #Nat64;

            case (#Int(_)) #Int;
            case (#Int8(_)) #Int8;
            case (#Int16(_)) #Int16;
            case (#Int32(_)) #Int32;
            case (#Int64(_)) #Int64;

            case (#Float32(_)) #Float32;
            case (#Float64(_)) #Float64;

            case (#Bool(_)) #Bool;

            case (#Principal(_)) #Principal;

            case (#Text(_)) #Text;

            case (#Null) #Null;

            case (#Option(optType)) {
                #Option(toArgType(optType));
            };
            case (#Vector(arr)) {
                #Vector(toArgType(arr[0]));
            };

            case (#Record(records)) {
                let newRecords = Array.map(
                    records,
                    func((key, val) : KeyValuePair) : RecordFieldType {
                        {
                            tag = #name(key);
                            _type = toArgType(val);
                        };
                    },
                );

                #Record(newRecords);
            };

            // case (#Variant(variants)) {
            //     let newVariants = Array.map(
            //         variants,
            //         func((key, val) : KeyValuePair) : RecordFieldType {
            //             {
            //                 tag = #name(key);
            //                 _type = toArgType(val);
            //             };
            //         },
            //     );

            //     #Variant(newVariants);
            // };

            case (_) { Prelude.unreachable() };
        };
    };

    func toArgValue(candid : Candid) : Value {
        switch (candid) {
            case (#Nat(n)) #Nat(n);
            case (#Nat8(n)) #Nat8(n);
            case (#Nat16(n)) #Nat16(n);
            case (#Nat32(n)) #Nat32(n);
            case (#Nat64(n)) #Nat64(n);

            case (#Int(n)) #Int(n);
            case (#Int8(n)) #Int8(n);
            case (#Int16(n)) #Int16(n);
            case (#Int32(n)) #Int32(n);
            case (#Int64(n)) #Int64(n);

            case (#Float32(n)) #Float32(n);
            case (#Float64(n)) #Float64(n);

            case (#Bool(b)) #Bool(b);

            case (#Principal(n)) #Principal(#transparent(n));

            case (#Text(n)) #Text(n);

            case (#Null) #Null;

            case (#Option(optVal)) {
                #Option(?toArgValue(optVal));
            };
            case (#Vector(arr)) {
                let transformedArr = Array.map(
                    arr,
                    func(elem : Candid) : Value {
                        toArgValue(elem);
                    },
                );

                #Vector(transformedArr);
            };

            case (#Record(records)) {
                let newRecords = Array.map(
                    records,
                    func((key, val) : KeyValuePair) : RecordFieldValue {
                        {
                            tag = #name(key);
                            value = toArgValue(val);
                        };

                    },
                );

                #Record(newRecords);
            };

            // case (#Variant(variants)) {
            //     let (key, val) = variants[0];

            //     let res = {
            //         tag = #name(key);
            //         value = toArgValue(val);
            //     };

            //     #Variant(res);
            // };

            case (_) { Prelude.unreachable() };
        };
    };
};
