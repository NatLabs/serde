import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int64 "mo:base/Int64";
import Int32 "mo:base/Int32";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

import T "Types";

module {
    public func toICRC3Value(candid_values : [T.Candid]) : [T.ICRC3Value] {

        func convert(candid : T.Candid) : T.ICRC3Value {
            switch (candid) {
                case (#Text(t)) #Text(t);
                case (#Nat(n)) #Nat(n);
                case (#Nat8(n)) #Nat(Nat8.toNat(n));
                case (#Nat16(n)) #Nat(Nat16.toNat(n));
                case (#Nat32(n)) #Nat(Nat32.toNat(n));
                case (#Nat64(n)) #Nat(Nat64.toNat(n));
                case (#Int(n)) #Int(n);
                case (#Int8(n)) #Int(Int8.toInt(n));
                case (#Int16(n)) #Int(Int16.toInt(n));
                case (#Int32(n)) #Int(Int32.toInt(n));
                case (#Int64(n)) #Int(Int64.toInt(n));
                case (#Blob(b)) #Blob(b);
                case (#Principal(p)) #Blob(Principal.toBlob(p));
                case (#Array(array_vals)) #Array(
                    Array.tabulate<T.ICRC3Value>(
                        array_vals.size(),
                        func(i : Nat) : T.ICRC3Value {
                            convert(array_vals.get(i));
                        },
                    )
                );
                case (#Record(record_vals) or #Map(record_vals)) #Map(
                    Array.tabulate<(Text, T.ICRC3Value)>(
                        record_vals.size(),
                        func(i : Nat) : (Text, T.ICRC3Value) {
                            let (key, value) = record_vals.get(i);
                            let icrc3_value = convert(value);
                            (key, icrc3_value);
                        },
                    )
                );
                case (#Bool(_) or #Option(_) or #Variant(_) or #Tuple(_)) Debug.trap(debug_show candid # " not suppported in ICRC3Value");
                case (#Empty) Debug.trap("Empty not suppported in ICRC3Value");
                case (#Float(f)) Debug.trap("Float not suppported in ICRC3Value");
                case (#Null) Debug.trap("Null not suppported in ICRC3Value");

            };

        };

        Array.tabulate<T.ICRC3Value>(
            candid_values.size(),
            func(i : Nat) : T.ICRC3Value {
                convert(candid_values.get(i));
            },
        );

    };

    public func fromICRC3Value(icrc3_values : [T.ICRC3Value]) : [T.Candid] {
        func convert(candid : T.ICRC3Value) : T.Candid {
            switch (candid) {
                case (#Text(t)) #Text(t);
                case (#Nat(n)) #Nat(n);
                case (#Int(n)) #Int(n);
                case (#Blob(b)) #Blob(b);
                case (#Array(array_vals)) #Array(
                    Array.tabulate<T.Candid>(
                        array_vals.size(),
                        func(i : Nat) : T.Candid {
                            convert(array_vals.get(i));
                        },
                    )
                );
                case (#Map(record_vals)) #Map(
                    Array.tabulate<(Text, T.Candid)>(
                        record_vals.size(),
                        func(i : Nat) : (Text, T.Candid) {
                            let (key, value) = record_vals.get(i);
                            let candid_value = convert(value);
                            (key, candid_value);
                        },
                    )
                );
            };
        };

        Array.tabulate(
            icrc3_values.size(),
            func(i : Nat) : T.Candid {
                convert(icrc3_values.get(i));
            },
        )

    };
};
