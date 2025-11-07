// @testmode wasi
import Blob "mo:base@0.16.0/Blob";
import Debug "mo:base@0.16.0/Debug";
import Iter "mo:base@0.16.0/Iter";
import Nat "mo:base@0.16.0/Nat";

import { test; suite } "mo:test";

import { Candid; JSON } "../src";

type User = {
    name : Text;
    id : ?Int;
};

suite(
    "JSON fromText()",
    func() {
        suite(
            "float type",
            func() {
                test(
                    "2 dp",
                    func() {
                        let text = "123.45";
                        let #ok(blob) = JSON.fromText(text, null);
                        let val : ?Float = from_candid (blob);

                        assert val == ?123.45;
                    },
                );
                test(
                    "8 dp",
                    func() {
                        let text = "123.123456789";
                        let #ok(blob) = JSON.fromText(text, null);
                        let val : ?Float = from_candid (blob);

                        assert val == ?123.123456789;
                    },
                );

                test(
                    "negative",
                    func() {
                        let text = "-123.123456789";
                        let #ok(blob) = JSON.fromText(text, null);
                        let val : ?Float = from_candid (blob);

                        assert val == ?-123.123456789;
                    },
                );
            },
        );
        test(
            "record type",
            func() {
                let text = "{\"name\": \"Tomi\", \"id\": 32}";
                let #ok(blob) = JSON.fromText(text, null);
                let user : ?User = from_candid (blob);

                assert user == ?{ name = "Tomi"; id = ?32 };
            },
        );
        test(
            "variant types",
            func() {

                type Variant = {
                    #text : Text;
                    #nat : Nat;
                    #bool : Bool;
                    #record : { site : Text };
                    #user : User;
                    #array : [Nat];
                };

                let text = "{\"#text\": \"hello\"}";
                let nat = "{\"#nat\": 123}";
                let bool = "{\"#bool\": true }";
                let record = "{\"#record\": {\"site\": \"github\"}}";
                let array = "{\"#array\": [1, 2, 3] }";

                let #ok(text_blob) = JSON.fromText(text, null);
                let #ok(nat_blob) = JSON.fromText(nat, null);
                let #ok(bool_blob) = JSON.fromText(bool, null);
                let #ok(record_blob) = JSON.fromText(record, null);
                let #ok(array_blob) = JSON.fromText(array, null);

                let text_val : ?Variant = from_candid (text_blob);
                let nat_val : ?Variant = from_candid (nat_blob);
                let bool_val : ?Variant = from_candid (bool_blob);
                let record_val : ?Variant = from_candid (record_blob);
                let array_val : ?Variant = from_candid (array_blob);

                assert (text_val == ?#text("hello"));
                assert (nat_val == ?#nat(123));
                assert (bool_val == ?#bool(true));
                assert (record_val == ?#record({ site = "github" }));
                assert (array_val == ?#array([1, 2, 3]));
            },
        );
        test(
            "multi-dimensional arrays",
            func() {
                let arr2 = "[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]]";
                let arr3 = "[[[\"hello\", \"world\"], [\"foo\", \"bar\"]], [[\"hello\", \"world\"], [\"foo\", \"bar\"]], [[\"hello\", \"world\"], [\"foo\", \"bar\"]]]";

                let #ok(arr2_blob) = JSON.fromText(arr2, null);
                let #ok(arr3_blob) = JSON.fromText(arr3, null);

                let arr2_encoded : ?[[Nat]] = from_candid (arr2_blob);
                let arr3_encoded : ?[[[Text]]] = from_candid (arr3_blob);

                assert (arr2_encoded == ?[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]]);
                assert (
                    arr3_encoded == ?[
                        [["hello", "world"], ["foo", "bar"]],
                        [["hello", "world"], ["foo", "bar"]],
                        [["hello", "world"], ["foo", "bar"]],
                    ]
                );
            },
        );
        test(
            "renaming record fields",
            func() {
                // type Original = {
                //     label : Nat;
                //     query : Text;
                // };

                type UserData = {
                    account_label : Nat;
                    user_query : Text;
                };

                let text = "{\"label\": 123, \"query\": \"?user_id=12&address=2014%20Forest%20Hill%20Drive\"}";

                let options = {
                    Candid.defaultOptions with
                    renameKeys = [("label", "account_label"), ("query", "user_query")];
                };

                let #ok(blob) = JSON.fromText(text, ?options);

                let user : ?UserData = from_candid (blob);
                assert user == ?{
                    account_label = 123;
                    user_query = "?user_id=12&address=2014%20Forest%20Hill%20Drive";
                };
            },
        );

        test(
            "partial JSON to record",
            func() {

                type User = { name : Text; id : Int; email : ?Text };

                let text = "{\"name\": \"Tomi\", \"id\": 123 }";

                let #ok(blob) = JSON.fromText(text, null);
                let user : ?User = from_candid (blob);

                assert user == ?{ name = "Tomi"; id = 123; email = null };

                let text2 = "{ \"name\": \"Tomi\", \"id\": 123, \"email\": \"test@gmail.com\" }";
                let #ok(blob2) = JSON.fromText(text2, null);
                let user2 : ?User = from_candid (blob2);
                assert user2 == ?{
                    name = "Tomi";
                    id = 123;
                    email = ?"test@gmail.com";
                };

                let jsonText = "[{\"name\": \"John\", \"id\": 123}, {\"name\": \"Jane\", \"id\": 456, \"email\": \"jane@gmail.com\"}]";

                let #ok(blob3) = JSON.fromText(jsonText, null); // you probably want to handle the error case here :)
                let users : ?[User] = from_candid (blob3);
                Debug.print(debug_show ({ users }));

                assert users == ?[
                    {
                        name = "John";
                        id = 123;
                        email = null;
                    },
                    {
                        name = "Jane";
                        id = 456;
                        email = ?"jane@gmail.com";
                    },
                ];
            },
        );
    },
);

suite(
    "JSON toText()",
    func() {
        test(
            "float",
            func() {
                let float : Float = 123.123456789;
                let blob = to_candid (float);
                let (jsonText) = JSON.toText(blob, [], null);

                assert jsonText == #ok("123.12");
            },
        );
        test(
            "toText()",
            func() {
                let user = { name = "Tomi"; id = null };
                let blob = to_candid (user);
                let (jsonText) = JSON.toText(blob, ["name", "id"], null);

                assert jsonText == #ok("{\"id\": null, \"name\": \"Tomi\"}");
            },
        );
        test(
            "variant types",
            func() {
                type Variant = {
                    #text : Text;
                    #nat : Nat;
                    #bool : Bool;
                    #record : { site : Text };
                    #array : [Nat];
                };

                let text = #text("hello");
                let nat = #nat(123);
                let bool = #bool(true);
                let record = #record({ site = "github" });
                let array = #array([1, 2, 3]);

                let text_blob = to_candid (text);
                let nat_blob = to_candid (nat);
                let bool_blob = to_candid (bool);
                let record_blob = to_candid (record);
                let array_blob = to_candid (array);

                let text_json = JSON.toText(text_blob, ["#text"], null);
                let nat_json = JSON.toText(nat_blob, ["#nat"], null);
                let bool_json = JSON.toText(bool_blob, ["bool"], null);
                let record_json = JSON.toText(record_blob, ["record", "site"], null);
                let array_json = JSON.toText(array_blob, ["array"], null);

                assert (text_json == #ok("{\"#text\": \"hello\"}"));
                assert (nat_json == #ok("{\"#nat\": 123}"));
                assert (bool_json == #ok("{\"#bool\": true}"));
                assert (record_json == #ok("{\"#record\": {\"site\": \"github\"}}"));
                assert (array_json == #ok("{\"#array\": [1, 2, 3]}"));
            },
        );
        test(
            "multi-dimensional arrays",
            func() {
                let arr2 : [[Nat]] = [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]];

                let arr3 : [[[Text]]] = [
                    [["hello", "world"], ["foo", "bar"]],
                    [["hello", "world"], ["foo", "bar"]],
                    [["hello", "world"], ["foo", "bar"]],
                ];

                assert (JSON.toText(to_candid (arr2), [], null) == #ok("[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]]"));
                assert (JSON.toText(to_candid (arr3), [], null) == #ok("[[[\"hello\", \"world\"], [\"foo\", \"bar\"]], [[\"hello\", \"world\"], [\"foo\", \"bar\"]], [[\"hello\", \"world\"], [\"foo\", \"bar\"]]]"));
            },
        );
        test(
            "renaming record fields",
            func() {
                // type Original = {
                //     label : Nat;   // reserved keyword that is renamed to account_label
                //     query : Text;  // reserved keyword that is renamed to user_query
                // };

                type UserData = {
                    account_label : Nat;
                    user_query : Text;
                };

                let UserDataKeys = ["account_label", "user_query"];
                let options = {
                    Candid.defaultOptions with
                    renameKeys = [("account_label", "label"), ("user_query", "query")];
                };

                let data : UserData = {
                    account_label = 123;
                    user_query = "?user_id=12&address=2014%20Forest%20Hill%20Drive";
                };
                let blob = to_candid (data);
                let jsonText = JSON.toText(blob, UserDataKeys, ?options);

                assert jsonText == #ok("{\"query\": \"?user_id=12&address=2014%20Forest%20Hill%20Drive\", \"label\": 123}");
            },
        );
    },
);
