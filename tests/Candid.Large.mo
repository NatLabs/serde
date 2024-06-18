// @testmode wasi
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Buffer "mo:base/Buffer";

import Fuzz "mo:fuzz";
import Itertools "mo:itertools/Iter";
import { test; suite } "mo:test";

import Serde "../src";

let fuzz = Fuzz.fromSeed(0x7eadbeef);

let limit = 1_000;

let candify_store_item = {
    from_blob = func(blob : Blob) : StoreItem {
        let ?c : ?StoreItem = from_candid (blob);
        c;
    };
    to_blob = func(c : StoreItem) : Blob { to_candid (c) };
};

type X = {
    name : Text;
    x : X;
};

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

type AvailableSizes = { #xs; #s: Nat; #m; #l; #xl };

type ColorOption = {
    name : Text;
    hex : Text;
};

type StoreItem = {
    name : Text;
    store : Text;
    customer_reviews : [CustomerReview];
    // available_sizes : AvailableSizes;
    color_options : [ColorOption];
    price : Float;
    in_stock : Bool;
    address : (Text, Text, Text, Text);
    // contact : {
    //     email : Text;
    //     phone : ?Text;
    // };
};


let cities = ["Toronto", "Ottawa", "New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose"];
let states = ["ON", "QC", "NY", "CA", "IL", "TX", "AZ", "PA", "TX", "CA", "TX", "CA"];
let streets = ["King St", "Queen St", "Yonge St", "Bay St", "Bloor St", "Dundas St", "College St", "Spadina Ave", "St Clair Ave", "Danforth Ave", "Eglinton Ave", "Lawrence Ave"];

let stores = ["h&m", "zara", "gap", "old navy", "forever 21", "uniqlo", "urban outfitters", "american eagle", "aeropostale", "abercrombie & fitch", "hollister", "express"];
let email_terminator = ["gmail.com", "yahoo.com", "outlook.com"];

let cs_starter_kid = ["black hoodie", "M1 macbook", "white hoodie", "air forces", "Algorithms textbook", "c the hard way", "Udemy subscription", "Nvidea RTX"];

let available_sizes = [#xs, #s, #m, #l, #xl];

func new_item() : StoreItem {
    let store_name = fuzz.array.randomEntry(stores).1;
    let store_item = {
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
        // available_sizes = #s(0);
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
        // contact = {
        //     email = store_name # "@" # fuzz.array.randomEntry(email_terminator).1;
        //     phone = if (fuzz.nat.randomRange(0, 100) % 3 == 0) { null } else {
        //         ?Text.fromIter(
        //             fuzz.array.randomArray<Char>(10, func() : Char { Char.fromNat32(fuzz.nat32.randomRange(0, 9) + Char.toNat32('0')) }).vals() : Iter.Iter<Char>
        //         );
        //     };
        // };
    };
};

let store_item_keys = ["name", "store", "customer_reviews", "username", "rating", "comment", "available_sizes", "xs", "s", "m", "l", "xl", "color_options", "name", "hex", "price", "in_stock", "address", "contact", "email", "phone"];

let candid_buffer = Buffer.Buffer<[Serde.Candid]>(limit);

suite(
    "Serde.Candid",
    func() {
        test(
            "decode()",
            func() {
                for (i in Itertools.range(0, limit)) {
                    let item = new_item();
                    let candid_blob = candify_store_item.to_blob(item);
                    let #ok(candid) = Serde.Candid.decode(candid_blob, store_item_keys, null);
                    candid_buffer.add(candid);
                };
            },
        );
        test(
            "encode()",
            func() {
                for (i in Itertools.range(0, limit)) {
                    Debug.print("i = " # debug_show i);
                    let candid = candid_buffer.get(i);
                    let res = Serde.Candid.encode(candid, null);
                    Debug.print("res = " # debug_show res);
                    let #ok(blob) = res;
                };
            },
        );
    },
);
