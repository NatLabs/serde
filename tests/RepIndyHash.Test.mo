import Blob "mo:base/Blob";
import Debug "mo:base/Debug";

import { test; suite } "mo:test";

import { Candid } "../src";

import RepIndyHash "mo:rep-indy-hash";

func validate_hash(candid_record : Candid.Candid, icrc3_value_record : RepIndyHash.Value) : Bool {
    let candid_hash = Candid.repIndyHash(candid_record);
    let expected = RepIndyHash.hash_val(icrc3_value_record) |> Blob.fromArray(_);

    candid_hash == expected;
};

suite(
    "Representation Independent Hash Test",
    func() {
        test(
            "#Nat",
            func() {
                assert validate_hash(#Nat(1), #Nat(1));
                assert validate_hash(#Nat(22345), #Nat(22345));

            },
        );

        test(
            "#Int",
            func() {
                let candid_record : Candid.Candid = #Int(42);
                let icrc3_value_record : RepIndyHash.Value = #Int(42);

                assert validate_hash(candid_record, icrc3_value_record);

            },
        );

        test(
            "#Text",
            func() {
                let candid_record : Candid.Candid = #Text("hello");
                let icrc3_value_record : RepIndyHash.Value = #Text("hello");

                assert validate_hash(candid_record, icrc3_value_record);
            },
        );

        test(
            "#Blob",
            func() {
                let candid_record : Candid.Candid = #Blob("\00\01\02");
                let icrc3_value_record : RepIndyHash.Value = #Blob("\00\01\02");

                assert validate_hash(candid_record, icrc3_value_record);
            },
        );

        test(
            "#Array",
            func() {
                let candid_record : Candid.Candid = #Array([#Text("hello"), #Text("world")]);
                let icrc3_value_record : RepIndyHash.Value = #Array([#Text("hello"), #Text("world")]);

                assert validate_hash(candid_record, icrc3_value_record);
            },
        );

        test(
            "#Record/#Map",
            func() {
                let candid_record : Candid.Candid = #Map([
                    ("a", #Nat(1)),
                    ("b", #Array([#Text("hello"), #Text("world")])),
                    ("c", #Blob("\00\01\02")),
                    ("d", #Int(42)),
                ]);
                let icrc3_value_record : RepIndyHash.Value = #Map([
                    ("a", #Nat(1)),
                    ("b", #Array([#Text("hello"), #Text("world")])),
                    ("c", #Blob("\00\01\02")),
                    ("d", #Int(42)),
                ]);

                assert validate_hash(candid_record, icrc3_value_record);

            },
        );
    },
);
