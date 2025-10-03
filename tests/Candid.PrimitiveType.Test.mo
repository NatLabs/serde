// @testmode wasi
import Blob "mo:base@0.14.14/Blob";
import Debug "mo:base@0.14.14/Debug";
import Iter "mo:base@0.14.14/Iter";
import Nat "mo:base@0.14.14/Nat";
import Principal "mo:base@0.14.14/Principal";

import { test; suite } "mo:test@2.1.1";

import Serde "../src";
import Candid "../src/Candid";
import Encoder "../src/Candid/Blob/Encoder";
import Fuzz "mo:fuzz@1.0.0";

let fuzz = Fuzz.fromSeed(0x12345678);
let limit = 10_000;

suite(
    "Candid Primitive Type Test",
    func() {

        // Int
        test(
            "Int",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let int : Int = fuzz.int.randomRange(-(2 ** 63), (2 ** 63) - 1);

                    let candid_encoding = to_candid (int);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    // Debug.print("Candid mismatch for Int: " # debug_show (int, candid_variant));

                    assert candid_variant == #ok([#Int(int)]);
                };
            },
        );

        // Nat8
        test(
            "Nat8",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let nat8 : Nat8 = fuzz.nat8.random();

                    let candid_encoding = to_candid (nat8);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Nat8(nat8)]);
                };
            },
        );

        // Nat16
        test(
            "Nat16",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let nat16 : Nat16 = fuzz.nat16.random();

                    let candid_encoding = to_candid (nat16);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Nat16(nat16)]);
                };
            },
        );

        // Nat32
        test(
            "Nat32",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let nat32 : Nat32 = fuzz.nat32.random();

                    let candid_encoding = to_candid (nat32);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Nat32(nat32)]);
                };
            },
        );

        // Nat64
        test(
            "Nat64",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let nat64 : Nat64 = fuzz.nat64.random();

                    let candid_encoding = to_candid (nat64);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Nat64(nat64)]);
                };
            },
        );

        // Int8
        test(
            "Int8",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let int8 : Int8 = fuzz.int8.random();

                    let candid_encoding = to_candid (int8);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Int8(int8)]);
                };
            },
        );

        // Int16
        test(
            "Int16",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let int16 : Int16 = fuzz.int16.random();

                    let candid_encoding = to_candid (int16);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Int16(int16)]);
                };
            },
        );

        // Int32
        test(
            "Int32",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let int32 : Int32 = fuzz.int32.random();

                    let candid_encoding = to_candid (int32);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Int32(int32)]);
                };
            },
        );

        // Int64
        test(
            "Int64",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let int64 : Int64 = fuzz.int64.random();

                    let candid_encoding = to_candid (int64);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Int64(int64)]);
                };
            },
        );

        // Text
        test(
            "Text",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let text : Text = fuzz.text.randomAlphanumeric(fuzz.nat.randomRange(0, 20));

                    let candid_encoding = to_candid (text);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Text(text)]);
                };
            },
        );

        // Principal
        test(
            "Principal",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let principal : Principal = fuzz.principal.randomPrincipal(29);

                    let candid_encoding = to_candid (principal);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Principal(principal)]);
                };
            },
        );

        // Blob
        test(
            "Blob",
            func() {
                for (_ in Iter.range(1, limit)) {
                    let blob : Blob = fuzz.blob.randomBlob(fuzz.nat.randomRange(0, 20));

                    let candid_encoding = to_candid (blob);
                    let candid_variant = Candid.decode(candid_encoding, [], null);

                    assert candid_variant == #ok([#Blob(blob)]);
                };
            },
        );

    },
);
