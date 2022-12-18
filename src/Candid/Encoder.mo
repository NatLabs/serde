import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Prelude "mo:base/Prelude";

import Encoder "mo:candid/Encoder";
import Decoder "mo:candid/Decoder";
import Arg "mo:candid/Arg";
import Value "mo:candid/Value";
import Type "mo:candid/Type";

import T "Types";
import U "../Utils";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;

    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    public func encode(candid : Candid) : Blob {
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
            case (#Nat(_)) #nat;
            case (#Nat8(_)) #nat8;
            case (#Nat16(_)) #nat16;
            case (#Nat32(_)) #nat32;
            case (#Nat64(_)) #nat64;

            case (#Int(_)) #int;
            case (#Int8(_)) #int8;
            case (#Int16(_)) #int16;
            case (#Int32(_)) #int32;
            case (#Int64(_)) #int64;

            case (#Float(_)) #float64;

            case (#Bool(_)) #bool;

            case (#Principal(_)) #principal;

            case (#Text(_)) #text;

            case (#Null) #_null;

            case (#Option(optType)) {
                #opt(toArgType(optType));
            };
            case (#Array(arr)) {
                #vector(toArgType(arr[0]));
            };

            case (#Record(records)) {
                let newRecords = Array.map(
                    Array.sort(records, U.cmpRecords),
                    func((key, val) : KeyValuePair) : RecordFieldType {
                        {
                            tag = #name(key);
                            _type = toArgType(val);
                        };
                    },
                );

                #record(newRecords);
            };

            case (#Variant((key, val))) {

                #variant([{
                    tag = #name(key);
                    _type = toArgType(val);
                }]);
            };

            case (c) Prelude.unreachable();
        };
    };

    func toArgValue(candid : Candid) : Value {
        switch (candid) {
            case (#Nat(n)) #nat(n);
            case (#Nat8(n)) #nat8(n);
            case (#Nat16(n)) #nat16(n);
            case (#Nat32(n)) #nat32(n);
            case (#Nat64(n)) #nat64(n);

            case (#Int(n)) #int(n);
            case (#Int8(n)) #int8(n);
            case (#Int16(n)) #int16(n);
            case (#Int32(n)) #int32(n);
            case (#Int64(n)) #int64(n);

            case (#Float(n)) #float64(n);

            case (#Bool(b)) #bool(b);

            case (#Principal(n)) #principal(#transparent(n));

            case (#Text(n)) #text(n);

            case (#Null) #_null;

            case (#Option(optVal)) {
                #opt(?toArgValue(optVal));
            };
            case (#Array(arr)) {
                let transformedArr = Array.map(
                    arr,
                    func(elem : Candid) : Value {
                        toArgValue(elem);
                    },
                );

                #vector(transformedArr);
            };

            case (#Record(records)) {
                let newRecords = Array.map(
                    Array.sort(records, U.cmpRecords),
                    func((key, val) : KeyValuePair) : RecordFieldValue {
                        {
                            tag = #name(key);
                            value = toArgValue(val);
                        };
                    },
                );

                #record(newRecords);
            };

            case (#Variant((key, val))) {

                #variant({
                    tag = #name(key);
                    value = toArgValue(val);
                });
            };

            case (c) Prelude.unreachable();
        };
    };
};
