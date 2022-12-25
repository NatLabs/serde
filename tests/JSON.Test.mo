import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

import JSON "../src/JSON";
import Candid "../src/Candid";

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
                            "fromText()",
                            do {
                                let text = "{\"name\": \"Tomi\", \"id\": 32}";
                                let blob = JSON.fromText(text);
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

                                let text_blob = JSON.fromText(text);
                                let nat_blob = JSON.fromText(nat);
                                let bool_blob = JSON.fromText(bool);
                                let record_blob = JSON.fromText(record);
                                let array_blob = JSON.fromText(array);

                                let text_val : ?Variant = from_candid (text_blob);
                                let nat_val : ?Variant = from_candid (nat_blob);
                                let bool_val : ?Variant = from_candid (bool_blob);
                                let record_val : ?Variant = from_candid (record_blob);
                                let array_val : ?Variant = from_candid (array_blob);

                                assertAllTrue([
                                    text_val == ?#text("hello"),
                                    nat_val == ?#nat(123),
                                    bool_val == ?#bool(true),
                                    record_val == ?#record({
                                        site = "github";
                                    }),
                                    array_val == ?#array([1, 2, 3]),
                                ]);
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
                                let jsonText = JSON.toText(blob, ["name", "id"]);

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

                                let text_json = JSON.toText(text_blob, ["text"]);
                                let nat_json = JSON.toText(nat_blob, ["nat"]);
                                let bool_json = JSON.toText(bool_blob, ["bool"]);
                                let record_json = JSON.toText(record_blob, ["record", "site"]);
                                let array_json = JSON.toText(array_blob, ["array"]);

                                assertAllTrue([
                                    text_json == "{\"#text\": \"hello\"}",
                                    nat_json == "{\"#nat\": 123}",
                                    bool_json == "{\"#bool\": true}",
                                    record_json == "{\"#record\": {\"site\": \"github\"}}",
                                    array_json == "{\"#array\": [1, 2, 3]}",
                                ]);
                            },
                        ),
                    ],
                ),
            ],
        ),
    ],
);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
