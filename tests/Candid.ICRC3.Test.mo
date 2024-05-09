// @testmode wasi
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import { test; suite } "mo:test";

import { Candid } "../src";

suite(
    "Candid ICRC3 compatability Test",
    func() {
        test(
            "record",
            func() {
                let record = { a = 1; b = 2; };

                let record_candid_blob = to_candid(record);

                let options = { Candid.defaultOptions with use_icrc_3_value_type = true; };
                let #ok(record_candid) = Candid.decode(record_candid_blob, ["a", "b"], ?options);

                assert record_candid[0] == #Map([
                    ("a", #Nat(1)),
                    ("b", #Nat(2)),
                ]);

                let #ok(record_candid_blob2) = Candid.encode(record_candid, ?options);

                assert record_candid_blob == record_candid_blob2;

                let ?record2 : ?{a: Nat; b: Nat;} = from_candid(record_candid_blob2);

                assert record2 == record;

            },
        );

        
    },
);
