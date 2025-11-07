import Iter "mo:base@0.16.0/Iter";
import Debug "mo:base@0.16.0/Debug";
import Prelude "mo:base@0.16.0/Prelude";
import Text "mo:base@0.16.0/Text";
import Char "mo:base@0.16.0/Char";
import Buffer "mo:base@0.16.0/Buffer";

import Bench "mo:bench";
import Fuzz "mo:fuzz";
import Itertools "mo:itertools@0.2.2/Iter";

import Serde "../src";
import CandidEncoder "../src/Candid/Blob/Encoder";
import CandidDecoder "../src/Candid/Blob/Decoder";

module {
    public func init() : Bench.Bench {
        let bench = Bench.Bench();

        bench.name("Benchmarking Serde");
        bench.description("Benchmarking the performance with 10k calls");

        bench.rows([
            "Serde: One Shot",
            "Serde: One Shot sans type inference",
            "Motoko (to_candid(), from_candid())",
            "Serde: Single Type Serializer",
        ]);

        bench.cols([
            "decode()",
            "encode()",
        ]);

        type Candid = Serde.Candid;

        let fuzz = Fuzz.Fuzz();

        let limit = 1_000;

        type CustomerReview = {
            username : Text;
            rating : Nat;
            comment : Text;
        };

        type AvailableSizes = { #xs; #s; #m; #l; #xl };

        type ColorOption = {
            name : Text;
            hex : Text;
        };

        // partial types for StoreItem
        // as mo:motoko_candid is limited and throws errors on some complex types
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

        let CustomerReview = #Record([
            ("username", #Text),
            ("comment", #Text),
            ("rating", #Nat),
        ]);

        let AvailableSizes = #Variant([("xs", #Null), ("s", #Null), ("m", #Null), ("l", #Null), ("xl", #Null)]);

        let ColorOption = #Record([
            ("name", #Text),
            ("hex", #Text),
        ]);

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

        let candify_store_item = {
            from_blob = func(blob : Blob) : StoreItem {
                let ?c : ?StoreItem = from_candid (blob);
                c;
            };
            to_blob = func(c : StoreItem) : Blob { to_candid (c) };
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

        let buffer = Buffer.Buffer<StoreItem>(limit);
        let candid_blobs = Buffer.Buffer<Blob>(limit);
        let candid_buffer = Buffer.Buffer<[Serde.Candid]>(limit);

        for (i in Itertools.range(0, limit)) {
            let item = new_item();
            buffer.add(item);
        };

        let StoreItemKeys = ["name", "store", "customer_reviews", "username", "rating", "comment", "available_sizes", "xs", "s", "m", "l", "xl", "color_options", "name", "hex", "price", "in_stock", "address", "contact", "email", "phone"];

        bench.runner(
            func(row, col) = switch (row, col) {
                case ("Motoko (to_candid(), from_candid())", "encode()") {
                    for (i in Itertools.range(0, limit)) {
                        let item = buffer.get(i);
                        let candid = to_candid (item);
                        // candid_blobs.add(candid);
                    };
                };
                case ("Motoko (to_candid(), from_candid())", "decode()") {
                    for (i in Itertools.range(0, limit)) {
                        let blob = candid_blobs.get(i);
                        let ?store_item : ?StoreItem = from_candid (blob);
                    };
                };

                case ("Serde: One Shot", "decode()") {
                    for (i in Itertools.range(0, limit)) {
                        let item = buffer.get(i);
                        let candid_blob = candify_store_item.to_blob(item);
                        candid_blobs.add(candid_blob);
                        let #ok(candid) = CandidDecoder.one_shot(candid_blob, StoreItemKeys, null);
                        candid_buffer.add(candid);
                    };
                };
                case ("Serde: One Shot", "encode()") {
                    for (i in Itertools.range(0, limit)) {
                        let candid = candid_buffer.get(i);
                        let res = CandidEncoder.one_shot(candid, null);
                        let #ok(blob) = res;
                    };
                };

                case ("Serde: One Shot sans type inference", "decode()") {
                    for (i in Itertools.range(0, limit)) {
                        let item = buffer.get(i);
                        let candid_blob = candify_store_item.to_blob(item);

                        let options = {
                            Serde.Candid.defaultOptions with types = ?FormattedStoreItem
                        };

                        let #ok(candid) = CandidDecoder.one_shot(candid_blob, StoreItemKeys, ?options);
                        // candid_buffer.add(candid);
                    };
                };

                case ("Serde: One Shot sans type inference", "encode()") {
                    for (i in Itertools.range(0, limit)) {
                        let candid = candid_buffer.get(i);

                        let options = {
                            Serde.Candid.defaultOptions with types = ?FormattedStoreItem
                        };
                        let res = CandidEncoder.one_shot(candid, ?options);
                        let #ok(blob) = res;
                    };
                };

                case ("Serde: Single Type Serializer", "decode()") {
                    let options = {
                        Serde.Candid.defaultOptions with types = ?FormattedStoreItem
                    };
                    let serializer = Serde.Candid.TypedSerializer.fromBlob(candify_store_item.to_blob(buffer.get(0)), StoreItemKeys, ?options);

                    for (i in Itertools.range(0, limit)) {
                        let item = buffer.get(i);
                        let candid_blob = candify_store_item.to_blob(item);

                        let #ok(candid) = Serde.Candid.TypedSerializer.decode(serializer, candid_blob);
                        // candid_buffer.add(candid);
                    };
                };

                case ("Serde: Single Type Serializer", "encode()") {

                    let serializer = Serde.Candid.TypedSerializer.new(FormattedStoreItem, null);

                    for (i in Itertools.range(0, limit)) {
                        let candid = candid_buffer.get(i);
                        let res = Serde.Candid.TypedSerializer.encode(serializer, candid);
                    };
                };

                case (_, _) {
                    Debug.trap("Should be unreachable:\n row = \"" # debug_show row # "\" and col = \"" # debug_show col # "\"");
                };
            }
        );

        bench;
    };
};
