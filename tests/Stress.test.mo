// @testmode wasi
import Iter "mo:base@0.16.0/Iter";
import Debug "mo:base@0.16.0/Debug";
import Prelude "mo:base@0.16.0/Prelude";
import Text "mo:base@0.16.0/Text";
import Char "mo:base@0.16.0/Char";
import Buffer "mo:base@0.16.0/Buffer";
import Nat64 "mo:base@0.16.0/Nat64";

import Fuzz "mo:fuzz";
import Itertools "mo:itertools@0.2.2/Iter";
import { test; suite } "mo:test";

import Serde "../src";
import CandidEncoder "../src/Candid/Blob/Encoder";
import CandidDecoder "../src/Candid/Blob/Decoder";
import LegacyCandidDecoder "../src/Candid/Blob/Decoder";
import LegacyCandidEncoder "../src/Candid/Blob/Encoder";

import CandidTestUtils "CandidTestUtils";

func createGenerator(seed : Nat) : { next() : Nat } {
    // Pure bitwise xorshift64 - no multiplication or addition!
    var state : Nat64 = Nat64.fromNat(seed);
    if (state == 0) state := 1; // Avoid zero state

    {
        next = func() : Nat {
            // Only XOR and bit shifts - fastest possible
            state ^= state << 13 : Nat64;
            state ^= state >> 7 : Nat64;
            state ^= state << 17 : Nat64;
            Nat64.toNat(state);
        };
    };
};

let fuzz = Fuzz.create(createGenerator(42));

let limit = 1_000;

let candify_store_item = {
    from_blob = func(blob : Blob) : StoreItem {
        let ?c : ?StoreItem = from_candid (blob);
        c;
    };
    to_blob = func(c : StoreItem) : Blob { to_candid (c) };
};

type X = { name : Text; x : X };

// let x: X = {
//     name = "yo";
//     x = {
//         name = "yo";
//         x = {};
//     };
// };

// let x : Serde.Candid = #Record([
//     ("name", #Text("yo")),
//     ("x", x)
// ]);
type CustomerReview = {
    username : Text;
    rating : Nat;
    comment : Text;
};

let CustomerReview = #Record([
    ("username", #Text),
    ("rating", #Nat),
    ("comment", #Text),
]);

type AvailableSizes = { #xs; #s; #m; #l; #xl };

let AvailableSizes = #Variant([
    ("xs", #Null),
    ("s", #Null),
    ("m", #Null),
    ("l", #Null),
    ("xl", #Null),
]);

type ColorOption = {
    name : Text;
    hex : Text;
};

let ColorOption = #Record([
    ("name", #Text),
    ("hex", #Text),
]);

type StoreItem = {
    name : Text;
    store : Text;
    customer_reviews : [CustomerReview];
    available_sizes : AvailableSizes;
    color_options : [ColorOption];
    price : Float;
    in_stock : Bool;
    address : (Text, Text, Text, Text);
    contact : {
        email : Text;
        phone : ?Text;
    };
};

let StoreItem : Serde.Candid.CandidType = #Record([
    ("name", #Text),
    ("store", #Text),
    ("customer_reviews", #Array(CustomerReview)),
    ("available_sizes", AvailableSizes),
    ("color_options", #Array(ColorOption)),
    ("price", #Float),
    ("in_stock", #Bool),
    ("address", #Tuple([#Text, #Text, #Text, #Text])),
    ("contact", #Record([("email", #Text), ("phone", #Option(#Text))])),
]);

let FormattedStoreItem = Serde.Candid.formatCandidType([StoreItem], null);

let cities = ["Toronto", "Ottawa", "New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose"];
let states = ["ON", "QC", "NY", "CA", "IL", "TX", "AZ", "PA", "TX", "CA", "TX", "CA"];
let streets = ["King St", "Queen St", "Yonge St", "Bay St", "Bloor St", "Dundas St", "College St", "Spadina Ave", "St Clair Ave", "Danforth Ave", "Eglinton Ave", "Lawrence Ave"];

let stores = ["h&m", "zara", "gap", "old navy", "forever 21", "uniqlo", "urban outfitters", "american eagle", "aeropostale", "abercrombie & fitch", "hollister", "express"];
let email_terminator = ["gmail.com", "yahoo.com", "outlook.com"];

let cs_starter_kid = ["black hoodie", "M1 macbook", "white hoodie", "air forces", "Algorithms textbook", "c the hard way", "Udemy subscription", "Nvidea RTX"];

let available_sizes = [#xs, #s, #m, #l, #xl];

func new_item() : StoreItem {
    let store_name = fuzz.array.randomEntry(stores).1;
    let store_item : StoreItem = {
        name = fuzz.array.randomEntry(cs_starter_kid).1;
        store = store_name;
        customer_reviews = [
            {
                username = "user1";
                rating = fuzz.nat.randomRange(0, 5);
                comment = "good";
            },
            {
                username = "user2";
                rating = fuzz.nat.randomRange(0, 5);
                comment = "ok";
            },
        ];
        available_sizes = fuzz.array.randomEntry(available_sizes).1;
        color_options = [
            { name = "red"; hex = "#ff0000" },
            { name = "blue"; hex = "#0000ff" },
        ];
        price = fuzz.float.randomRange(19.99, 399.99);
        in_stock = fuzz.bool.random();
        address = (
            fuzz.array.randomEntry(streets).1,
            fuzz.array.randomEntry(cities).1,
            fuzz.array.randomEntry(states).1,
            fuzz.text.randomAlphanumeric(6),
        );
        contact = {
            email = store_name # "@" # fuzz.array.randomEntry(email_terminator).1;
            phone = if (fuzz.nat.randomRange(0, 100) % 3 == 0) { null } else {
                ?Text.fromIter(
                    fuzz.array.randomArray<Char>(10, func() : Char { Char.fromNat32(fuzz.nat32.randomRange(0, 9) + Char.toNat32('0')) }).vals() : Iter.Iter<Char>
                );
            };
        };
    };
};

let store_item_keys = ["name", "store", "customer_reviews", "username", "rating", "comment", "available_sizes", "xs", "s", "m", "l", "xl", "color_options", "name", "hex", "price", "in_stock", "address", "contact", "email", "phone"];

let candid_buffer = Buffer.Buffer<[Serde.Candid]>(limit);
let store_items = Buffer.Buffer<StoreItem>(limit);

let candid_buffer_with_types = Buffer.Buffer<[Serde.Candid]>(limit);
let store_items_with_types = Buffer.Buffer<StoreItem>(limit);

// Roundtrip test function that takes a schema, value generator, and comparison function
func roundtripTest<T>(
    schema : Serde.Candid.CandidType,
    valueGenerator : () -> T,
    toBlobFn : (T) -> Blob,
    fromBlobFn : (Blob) -> T,
    keys : [Text],
    iterations : Nat,
) : () {
    let values = Buffer.Buffer<T>(iterations);
    let candid_values = Buffer.Buffer<[Serde.Candid]>(iterations);

    // Phase 1: Generate values and decode them to Candid
    for (i in Itertools.range(0, iterations)) {
        let value = valueGenerator();
        values.add(value);
        let blob = toBlobFn(value);
        let #ok(candid) = CandidDecoder.one_shot(blob, keys, null);
        candid_values.add(candid);
    };

    // Phase 2: Encode Candid values back to blobs and verify roundtrip
    for (i in Itertools.range(0, iterations)) {
        let candid = candid_values.get(i);
        let originalValue = values.get(i);

        // Use CandidTestUtils.encode_with_types for consistency validation
        let #ok(encodedBlob) = CandidTestUtils.encode_with_types([schema], candid, null);
        let decodedValue = fromBlobFn(encodedBlob);

        assert decodedValue == originalValue;
    };
};

suite(
    "Serde.Candid",
    func() {
        test(
            "decode()",
            func() {
                for (i in Itertools.range(0, limit)) {
                    let item = new_item();
                    store_items.add(item);
                    let candid_blob = candify_store_item.to_blob(item);
                    let #ok(candid) = CandidDecoder.one_shot(candid_blob, store_item_keys, null);
                    candid_buffer.add(candid);
                };
            },
        );
        test(
            "encode()",
            func() {
                for (i in Itertools.range(0, limit)) {
                    let candid = candid_buffer.get(i);
                    let res = LegacyCandidEncoder.encode(candid, null);
                    let #ok(blob) = res;
                    let item = candify_store_item.from_blob(blob);
                    Debug.print("item: " # debug_show item);
                    Debug.print("store_items: " # debug_show store_items.get(i));
                    assert item == store_items.get(i);
                };
            },
        );
        test(
            "decode() with types",
            func() {
                for (i in Itertools.range(0, limit)) {
                    let item = new_item();
                    store_items_with_types.add(item);
                    let candid_blob = candify_store_item.to_blob(item);
                    let #ok(split_blob) = CandidDecoder.split(candid_blob, null);
                    let #ok(candid) = CandidDecoder.one_shot(candid_blob, store_item_keys, ?{ Serde.Candid.defaultOptions with types = ?FormattedStoreItem });
                    candid_buffer_with_types.add(candid);
                };
            },
        );
        test(
            "encode() with types",
            func() {
                for (i in Itertools.range(0, limit)) {
                    let candid = candid_buffer_with_types.get(i);
                    let res = LegacyCandidEncoder.encode(candid, ?{ Serde.Candid.defaultOptions with types = ?FormattedStoreItem });
                    let #ok(blob) = res;
                    let item = candify_store_item.from_blob(blob);
                    assert item == store_items_with_types.get(i);
                };
            },
        );

        test(
            "roundtrip StoreItem with schema validation",
            func() {
                roundtripTest<StoreItem>(
                    StoreItem,
                    new_item,
                    candify_store_item.to_blob,
                    candify_store_item.from_blob,
                    store_item_keys,
                    100 // Smaller iteration count for this test
                );
            },
        );
    },
);

suite(
    "Roundtrip Tests",
    func() {
        test(
            "roundtrip simple record",
            func() {
                type SimpleRecord = { name : Text; age : Nat };
                let SimpleRecordSchema : Serde.Candid.CandidType = #Record([("name", #Text), ("age", #Nat)]);

                let simpleRecordUtils = {
                    to_blob = func(r : SimpleRecord) : Blob { to_candid (r) };
                    from_blob = func(blob : Blob) : SimpleRecord {
                        let ?r : ?SimpleRecord = from_candid (blob);
                        r;
                    };
                };

                roundtripTest<SimpleRecord>(
                    SimpleRecordSchema,
                    func() : SimpleRecord {
                        {
                            name = fuzz.text.randomAlphanumeric(10);
                            age = fuzz.nat.randomRange(0, 100);
                        };
                    },
                    simpleRecordUtils.to_blob,
                    simpleRecordUtils.from_blob,
                    ["name", "age"],
                    100,
                );
            },
        );

        test(
            "roundtrip variant type",
            func() {
                type SimpleVariant = { #text : Text; #num : Nat; #flag : Bool };
                let SimpleVariantSchema : Serde.Candid.CandidType = #Variant([("text", #Text), ("num", #Nat), ("flag", #Bool)]);

                let simpleVariantUtils = {
                    to_blob = func(v : SimpleVariant) : Blob { to_candid (v) };
                    from_blob = func(blob : Blob) : SimpleVariant {
                        let ?v : ?SimpleVariant = from_candid (blob);
                        v;
                    };
                };

                roundtripTest<SimpleVariant>(
                    SimpleVariantSchema,
                    func() : SimpleVariant {
                        switch (fuzz.nat.randomRange(0, 2)) {
                            case (0) { #text(fuzz.text.randomAlphanumeric(5)) };
                            case (1) { #num(fuzz.nat.randomRange(0, 1000)) };
                            case (_) { #flag(fuzz.bool.random()) };
                        };
                    },
                    simpleVariantUtils.to_blob,
                    simpleVariantUtils.from_blob,
                    ["text", "num", "flag"],
                    100,
                );
            },
        );

        test(
            "roundtrip array type",
            func() {
                let ArraySchema : Serde.Candid.CandidType = #Array(#Nat);

                let arrayUtils = {
                    to_blob = func(arr : [Nat]) : Blob { to_candid (arr) };
                    from_blob = func(blob : Blob) : [Nat] {
                        let ?arr : ?[Nat] = from_candid (blob);
                        arr;
                    };
                };

                roundtripTest<[Nat]>(
                    ArraySchema,
                    func() : [Nat] {
                        fuzz.array.randomArray<Nat>(fuzz.nat.randomRange(0, 10), func() : Nat { fuzz.nat.randomRange(0, 1000) });
                    },
                    arrayUtils.to_blob,
                    arrayUtils.from_blob,
                    [],
                    100,
                );
            },
        );

        test(
            "roundtrip optional type",
            func() {
                let OptionalSchema : Serde.Candid.CandidType = #Option(#Text);

                let optionalUtils = {
                    to_blob = func(opt : ?Text) : Blob { to_candid (opt) };
                    from_blob = func(blob : Blob) : ?Text {
                        let ?opt : ??Text = from_candid (blob);
                        opt;
                    };
                };

                roundtripTest<?Text>(
                    OptionalSchema,
                    func() : ?Text {
                        if (fuzz.bool.random()) {
                            ?fuzz.text.randomAlphanumeric(8);
                        } else {
                            null;
                        };
                    },
                    optionalUtils.to_blob,
                    optionalUtils.from_blob,
                    [],
                    100,
                );
            },
        );
    },
);
