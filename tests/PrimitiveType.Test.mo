// @testmode wasi
import Blob "mo:base@0.14.14/Blob";
import Debug "mo:base@0.14.14/Debug";
import Iter "mo:base@0.14.14/Iter";
import Nat "mo:base@0.14.14/Nat";
import Principal "mo:base@0.14.14/Principal";

import { test; suite } "mo:test";

import Serde "../src";
import Candid "../src/Candid";
import Encoder "../src/Candid/Blob/Encoder";
import Fuzz "mo:fuzz";

import CandidTestUtils "CandidTestUtils";

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

                    let IntType : Candid.CandidType = #Int;
                    let #ok(blob) = CandidTestUtils.encode_with_types([IntType], [#Int(int)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_int : ?Int = from_candid (candid_encoding);
                    assert decoded_int == ?int;
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

                    let Nat8Type : Candid.CandidType = #Nat8;
                    let #ok(blob) = CandidTestUtils.encode_with_types([Nat8Type], [#Nat8(nat8)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_nat8 : ?Nat8 = from_candid (candid_encoding);
                    assert decoded_nat8 == ?nat8;
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

                    let Nat16Type : Candid.CandidType = #Nat16;
                    let #ok(blob) = CandidTestUtils.encode_with_types([Nat16Type], [#Nat16(nat16)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_nat16 : ?Nat16 = from_candid (candid_encoding);
                    assert decoded_nat16 == ?nat16;
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

                    let Nat32Type : Candid.CandidType = #Nat32;
                    let #ok(blob) = CandidTestUtils.encode_with_types([Nat32Type], [#Nat32(nat32)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_nat32 : ?Nat32 = from_candid (candid_encoding);
                    assert decoded_nat32 == ?nat32;
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

                    let Nat64Type : Candid.CandidType = #Nat64;
                    let #ok(blob) = CandidTestUtils.encode_with_types([Nat64Type], [#Nat64(nat64)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_nat64 : ?Nat64 = from_candid (candid_encoding);
                    assert decoded_nat64 == ?nat64;
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

                    let Int8Type : Candid.CandidType = #Int8;
                    let #ok(blob) = CandidTestUtils.encode_with_types([Int8Type], [#Int8(int8)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_int8 : ?Int8 = from_candid (candid_encoding);
                    assert decoded_int8 == ?int8;
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

                    let Int16Type : Candid.CandidType = #Int16;
                    let #ok(blob) = CandidTestUtils.encode_with_types([Int16Type], [#Int16(int16)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_int16 : ?Int16 = from_candid (candid_encoding);
                    assert decoded_int16 == ?int16;
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

                    let Int32Type : Candid.CandidType = #Int32;
                    let #ok(blob) = CandidTestUtils.encode_with_types([Int32Type], [#Int32(int32)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_int32 : ?Int32 = from_candid (candid_encoding);
                    assert decoded_int32 == ?int32;
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

                    let Int64Type : Candid.CandidType = #Int64;
                    let #ok(blob) = CandidTestUtils.encode_with_types([Int64Type], [#Int64(int64)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_int64 : ?Int64 = from_candid (candid_encoding);
                    assert decoded_int64 == ?int64;
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

                    let TextType : Candid.CandidType = #Text;
                    let #ok(blob) = CandidTestUtils.encode_with_types([TextType], [#Text(text)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_text : ?Text = from_candid (candid_encoding);
                    assert decoded_text == ?text;
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

                    let PrincipalType : Candid.CandidType = #Principal;
                    let #ok(blob) = CandidTestUtils.encode_with_types([PrincipalType], [#Principal(principal)], null) else return assert false;
                    assert blob == candid_encoding;

                    let decoded_principal : ?Principal = from_candid (candid_encoding);
                    assert decoded_principal == ?principal;
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

                    let BlobType : Candid.CandidType = #Blob;
                    let #ok(encoded_blob) = CandidTestUtils.encode_with_types([BlobType], [#Blob(blob)], null) else return assert false;
                    Debug.print("comparing encoded blob: " # debug_show (encoded_blob));
                    Debug.print("with candid encoding: " # debug_show (candid_encoding));
                    assert encoded_blob == candid_encoding;

                    let decoded_blob : ?Blob = from_candid (candid_encoding);
                    assert decoded_blob == ?blob;
                };
            },
        );

    },
);
