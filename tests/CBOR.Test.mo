// @testmode wasi
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import { test; suite } "mo:test";

import { CBOR } "../src";

suite(
    "CBOR Test",
    func() {
        test("options", func() {
            let opt_nat_null: ?Nat = null;
            let opt_nat : ?Nat = ?123;
            let opt_text_null: ?Text = null;
            let opt_text : ?Text = ?"hello";

            let opt_nat_null_candid = to_candid(opt_nat_null);
            let opt_nat_candid = to_candid(opt_nat);
            let opt_text_null_candid = to_candid(opt_text_null);
            let opt_text_candid = to_candid(opt_text);

            let #ok(opt_nat_null_cbor) = CBOR.encode(opt_nat_null_candid, [], null);
            let #ok(opt_nat_cbor) = CBOR.encode(opt_nat_candid, [], null);
            let #ok(opt_text_null_cbor) = CBOR.encode(opt_text_null_candid, [], null);
            let #ok(opt_text_cbor) = CBOR.encode(opt_text_candid, [], null);

            let #ok(opt_nat_null_candid2) = CBOR.decode(opt_nat_null_cbor, null);
            let #ok(opt_nat_candid2) = CBOR.decode(opt_nat_cbor, null);
            let #ok(opt_text_null_candid2) = CBOR.decode(opt_text_null_cbor, null);
            let #ok(opt_text_candid2) = CBOR.decode(opt_text_cbor, null);

            assert opt_nat_null_candid != opt_nat_null_candid2;
            assert opt_nat_candid != opt_nat_candid2;
            assert opt_text_null_candid != opt_text_null_candid2;
            assert opt_text_candid != opt_text_candid2;

            let ?opt_nat_null2 : ?(?Nat) = from_candid(opt_nat_null_candid2);
            let ?opt_nat2 : ?(?Nat) = from_candid(opt_nat_candid2);
            let ?opt_text_null2 : ?(?Text) = from_candid(opt_text_null_candid2);
            let ?opt_text2 : ?(?Text) = from_candid(opt_text_candid2);

            assert opt_nat_null2 == opt_nat_null;
            assert opt_nat2 == opt_nat;
            assert opt_text_null2 == opt_text_null;
            assert opt_text2 == opt_text;

        });
        test(
            "primitives",
            func() {
                
                let nat : Nat = 123;
                let int : Int = -123;
                let float : Float = 123.456;
                let bool : Bool = true;
                let text: Text = "hello";
                let blob: Blob = "\01\02\03";
                let _null: Null = null;
                let empty = ();
                let list: [Nat] = [1, 2, 3];
                let record = { a = 1; b = 2; };

                let nat_candid = to_candid(nat);
                let int_candid = to_candid(int);
                let float_candid = to_candid(float);
                let bool_candid = to_candid(bool);
                let text_candid = to_candid(text);
                let blob_candid = to_candid(blob);
                let null_candid = to_candid(_null);
                let empty_candid = to_candid(empty);
                let list_candid = to_candid(list);
                let record_candid = to_candid(record);

                let #ok(nat_cbor) = CBOR.encode(nat_candid, [], null);
                let #ok(int_cbor) = CBOR.encode(int_candid, [], null);
                let #ok(float_cbor) = CBOR.encode(float_candid, [], null);
                let #ok(bool_cbor) = CBOR.encode(bool_candid, [], null);
                let #ok(text_cbor) = CBOR.encode(text_candid, [], null);
                let #ok(blob_cbor) = CBOR.encode(blob_candid, [], null);
                let #ok(null_cbor) = CBOR.encode(null_candid, [], null);
                let #ok(empty_cbor) = CBOR.encode(empty_candid, [], null);
                let #ok(list_cbor) = CBOR.encode(list_candid, [], null);
                let #ok(record_cbor) = CBOR.encode(record_candid, ["a", "b"], null);

                let #ok(nat_candid2) = CBOR.decode(nat_cbor, null);
                let #ok(int_candid2) = CBOR.decode(int_cbor, null);
                let #ok(float_candid2) = CBOR.decode(float_cbor, null);
                let #ok(bool_candid2) = CBOR.decode(bool_cbor, null);
                let #ok(text_candid2) = CBOR.decode(text_cbor, null);
                let #ok(blob_candid2) = CBOR.decode(blob_cbor, null);
                let #ok(null_candid2) = CBOR.decode(null_cbor, null);
                let #ok(empty_candid2) = CBOR.decode(empty_cbor, null);
                let #ok(list_candid2) = CBOR.decode(list_cbor, null);
                let #ok(record_candid2) = CBOR.decode(record_cbor, null);

                assert nat_candid == nat_candid2;
                assert int_candid == int_candid2;
                assert float_candid == float_candid2;
                assert bool_candid == bool_candid2;
                assert text_candid == text_candid2;
                assert blob_candid == blob_candid2;
                assert null_candid == null_candid2;
                assert empty_candid == empty_candid2;
                assert list_candid == list_candid2;
                assert record_candid == record_candid2;

            },
        );
    },
);
