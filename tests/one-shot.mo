// @testmode wasi
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import { test; suite } "mo:test";

import Candid "../src/Candid";

suite(
    "One Shot Candid Test",
    func() {

        test(
            "primitives",
            func() {

                let nat : Candid.Candid = #Nat(123);

                let encoded_nat = Candid.encodeOne(nat);
                
                // let int : Int = -123;
                // let float : Float = 123.456;
                // let bool : Bool = true;
                // let text : Text = "hello";
                // let blob : Blob = "\01\02\03";
                // let _null : Null = null;
                // let empty = ();
                // let list : [Nat] = [1, 2, 3];
                // let record = { a = 1; b = 2 };
                // let principal = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai");

            },
        );

    },
);
