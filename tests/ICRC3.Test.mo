// @testmode wasi
import Array "mo:base@0.16.0/Array";
import Blob "mo:base@0.16.0/Blob";
import Debug "mo:base@0.16.0/Debug";
import Iter "mo:base@0.16.0/Iter";
import Principal "mo:base@0.16.0/Principal";
import Text "mo:base@0.16.0/Text";

import { test; suite } "mo:test";

import Serde "../src";
import CandidTestUtils "CandidTestUtils";

let { Candid } = Serde;

suite(
    "Candid ICRC3 compatability Test",
    func() {
        test(
            "#Map",
            func() {
                let record = { a = 1; b = 2 };

                let record_candid_blob = to_candid (record);

                let options = {
                    Candid.defaultOptions with use_icrc_3_value_type = true;
                };
                let #ok(record_candid) = Candid.decode(record_candid_blob, ["a", "b"], ?options);

                assert record_candid[0] == #Map([
                    ("a", #Nat(1)),
                    ("b", #Nat(2)),
                ]);

                let RecordType : Candid.CandidType = #Map([("a", #Nat), ("b", #Nat)]);

                let #ok(record_candid_blob2) = CandidTestUtils.encode_with_types([RecordType], record_candid, ?options) else return assert false;

                assert record_candid_blob == record_candid_blob2;

                let ?record2 : ?{ a : Nat; b : Nat } = from_candid (record_candid_blob2);

                assert record2 == record;

            },
        );

    },

);

suite(
    "Connvert between motoko and ICRC3",
    func() {
        test(
            "motoko -> ICRC3",
            func() {

                type User = { id : Nat; name : Text };

                let user : User = { name = "bar"; id = 112 };

                let blob = to_candid (user);
                let #ok(candid_values) = Candid.decode(blob, ["name", "id"], null);
                let icrc3_values = Candid.toICRC3Value(candid_values);

                assert icrc3_values[0] == #Map([
                    ("id", #Nat(112)),
                    ("name", #Text("bar")),
                ]);
            },
        );

        test(
            "ICRC3 -> motoko",
            func() {
                type User = { name : Text; id : Nat };

                let icrc3 : Serde.ICRC3Value = #Map([
                    ("id", #Nat(112)),
                    ("name", #Text("bar")),
                ]);

                let candid_values = Candid.fromICRC3Value([icrc3]);

                let UserType : Candid.CandidType = #Record([("name", #Text), ("id", #Nat)]);

                let #ok(blob) = CandidTestUtils.encode_with_types([UserType], candid_values, null) else return assert false;
                let user : ?User = from_candid (blob);

                assert user == ?{ name = "bar"; id = 112 };
            },
        );
    },

);
