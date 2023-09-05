// @testmode wasi
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

import { Candid; JSON } "../src";

let {
    assertTrue;
    assertFalse;
    assertAllTrue;
    describe;
    it;
    skip;
    pending;
    run;
} = ActorSpec;

type User = {
    name : Text;
    id : ?Int;
};

let success = run(
    [
        describe(
            "JSON",
            [
                describe(
                    "fromText()",
                    [
                        it(
                            "record type",
                            do {
                                let text = "{\"name\": \"Tomi\", \"id\": 32}";
                                let blob = JSON.fromText(text, null);
                                let user : ?User = from_candid (blob);

                                user == ?{ name = "Tomi"; id = ?32 };
                            },
                        ),
                        it(
                            "variant types",
                            do {

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

                                let text_blob = JSON.fromText(text, null);
                                let nat_blob = JSON.fromText(nat, null);
                                let bool_blob = JSON.fromText(bool, null);
                                let record_blob = JSON.fromText(record, null);
                                let array_blob = JSON.fromText(array, null);

                                let text_val : ?Variant = from_candid (text_blob);
                                let nat_val : ?Variant = from_candid (nat_blob);
                                let bool_val : ?Variant = from_candid (bool_blob);
                                let record_val : ?Variant = from_candid (record_blob);
                                let array_val : ?Variant = from_candid (array_blob);

                                assertAllTrue([
                                    text_val == ? #text("hello"),
                                    nat_val == ? #nat(123),
                                    bool_val == ? #bool(true),
                                    record_val == ? #record({
                                        site = "github";
                                    }),
                                    array_val == ? #array([1, 2, 3]),
                                ]);
                            },
                        ),
                        it(
                            "multi-dimensional arrays",
                            do {
                                let arr2 = "[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]]";

                                let arr3 = "[[[\"hello\", \"world\"], [\"foo\", \"bar\"]], [[\"hello\", \"world\"], [\"foo\", \"bar\"]], [[\"hello\", \"world\"], [\"foo\", \"bar\"]]]";

                                let encoded_arr2 : ?[[Nat]] = from_candid (JSON.fromText(arr2, null));
                                let encoded_arr3 : ?[[[Text]]] = from_candid (JSON.fromText(arr3, null));

                                assertAllTrue([
                                    encoded_arr2 == ?[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]],
                                    encoded_arr3 == ?[
                                        [["hello", "world"], ["foo", "bar"]],
                                        [["hello", "world"], ["foo", "bar"]],
                                        [["hello", "world"], ["foo", "bar"]],
                                    ],
                                ]);
                            },
                        ),

                        it(
                            "renaming record fields",
                            do {
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
                                    renameKeys = [("label", "account_label"), ("query", "user_query")];
                                };
                                let blob = JSON.fromText(text, ?options);

                                let user : ?UserData = from_candid (blob);

                                user == ?{
                                    account_label = 123;
                                    user_query = "?user_id=12&address=2014%20Forest%20Hill%20Drive";
                                };
                            },
                        ),
                    ],
                ),
                describe(
                    "toText()",
                    [
                        it(
                            "toText()",
                            do {
                                let user = { name = "Tomi"; id = null };
                                let blob = to_candid (user);
                                let jsonText = JSON.toText(blob, ["name", "id"], null);

                                jsonText == "{\"id\": null, \"name\": \"Tomi\"}";
                            },
                        ),
                        it(
                            "variant types",
                            do {
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

                                assertAllTrue([
                                    text_json == "{\"#text\": \"hello\"}",
                                    nat_json == "{\"#nat\": 123}",
                                    bool_json == "{\"#bool\": true}",
                                    record_json == "{\"#record\": {\"site\": \"github\"}}",
                                    array_json == "{\"#array\": [1, 2, 3]}",
                                ]);
                            },
                        ),
                        it(
                            "multi-dimensional arrays",
                            do {
                                let arr2 : [[Nat]] = [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]];

                                let arr3 : [[[Text]]] = [
                                    [["hello", "world"], ["foo", "bar"]],
                                    [["hello", "world"], ["foo", "bar"]],
                                    [["hello", "world"], ["foo", "bar"]],
                                ];

                                assertAllTrue([
                                    JSON.toText(to_candid (arr2), [], null) == "[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]]",
                                    JSON.toText(to_candid (arr3), [], null) == "[[[\"hello\", \"world\"], [\"foo\", \"bar\"]], [[\"hello\", \"world\"], [\"foo\", \"bar\"]], [[\"hello\", \"world\"], [\"foo\", \"bar\"]]]",
                                ]);
                            },
                        ),
                        it(
                            "renaming record fields",
                            do {
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
                                    renameKeys = [("account_label", "label"), ("user_query", "query")];
                                };

                                let data : UserData = {
                                    account_label = 123;
                                    user_query = "?user_id=12&address=2014%20Forest%20Hill%20Drive";
                                };
                                let blob = to_candid (data);
                                let jsonText = JSON.toText(blob, UserDataKeys, ?options);

                                jsonText == "{\"label\": 123, \"query\": \"?user_id=12&address=2014%20Forest%20Hill%20Drive\"}";
                            },
                        ),
                    ],
                ),
            ],
        ),
    ]
);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
