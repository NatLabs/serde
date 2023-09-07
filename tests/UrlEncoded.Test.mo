// @testmode wasi
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

import ActorSpec "./utils/ActorSpec";

import UrlEncoded "../src/UrlEncoded";

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
    msg : Text;
};

let success = run([
    describe(
        "UrlEncoded Pairs",
        [
            describe(
                "fromText to motoko",
                [
                    it(
                        "single record",
                        do {

                            let blob = UrlEncoded.fromText("msg=Hello World&name=John", null);

                            let res : ?User = from_candid (blob);

                            assertTrue(
                                res == ?{
                                    name = "John";
                                    msg = "Hello World";
                                }
                            );
                        },
                    ),
                    it(
                        "pairs with empty values",
                        do {

                            let unknown_blob = UrlEncoded.fromText("msg=Hello&name=", null);
                            let known_blob = UrlEncoded.fromText("msg=Hello&name=John", null);

                            type UserOptionalName = {
                                name : ?Text;
                                msg : Text;
                            };

                            let unknown_user : ?UserOptionalName = from_candid (unknown_blob);
                            let known_user : ?UserOptionalName = from_candid (known_blob);

                            assertAllTrue([
                                unknown_user == ?{
                                    name = null;
                                    msg = "Hello";
                                },
                                known_user == ?{
                                    name = ?"John";
                                    msg = "Hello";
                                },
                            ]);
                        },
                    ),
                    it(
                        "record with array",
                        do {

                            let text = "users[0][name]=John&users[0][msg]=Hello World&users[1][name]=Jane&users[1][msg]=testing";
                            let blob = UrlEncoded.fromText(text, null);

                            let res : ?{ users : [User] } = from_candid (blob);
                            assertTrue(
                                res == ?{
                                    users = [
                                        {
                                            name = "John";
                                            msg = "Hello World";
                                        },
                                        {
                                            name = "Jane";
                                            msg = "testing";
                                        },
                                    ];
                                }
                            );
                        },
                    ),
                    it(
                        "variant type",
                        do {
                            type Variant = {
                                #text : Text;
                                #nat : Nat;
                                #int : Int;
                                #float : Float;
                                #bool : Bool;
                                #record : { site : Text };
                                #user : User;
                                #array : [Nat];
                            };

                            let text = "variant[#text]=hello";
                            let nat = "variant[#nat]=123";
                            let int = "variant[#int]=-123";
                            let float = "variant[#float]=-1.23";
                            let bool = "variant[#bool]=true";
                            let record = "variant[#record][site]=github";
                            let user = "variant[#user][name]=John&variant[#user][msg]=Hello World";
                            let array = "variant[#array][0]=1&variant[#array][1]=2&variant[#array][2]=3";

                            let text_blob = UrlEncoded.fromText(text, null);
                            let nat_blob = UrlEncoded.fromText(nat, null);
                            let int_blob = UrlEncoded.fromText(int, null);
                            let float_blob = UrlEncoded.fromText(float, null);
                            let bool_blob = UrlEncoded.fromText(bool, null);
                            let record_blob = UrlEncoded.fromText(record, null);
                            let user_blob = UrlEncoded.fromText(user, null);
                            let array_blob = UrlEncoded.fromText(array, null);

                            let text_val : ?{ variant : Variant } = from_candid (text_blob);
                            let nat_val : ?{ variant : Variant } = from_candid (nat_blob);
                            let int_val : ?{ variant : Variant } = from_candid (int_blob);
                            let float_val : ?{ variant : Variant } = from_candid (float_blob);
                            let bool_val : ?{ variant : Variant } = from_candid (bool_blob);
                            let record_val : ?{ variant : Variant } = from_candid (record_blob);
                            let user_val : ?{ variant : Variant } = from_candid (user_blob);
                            let array_val : ?{ variant : Variant } = from_candid (array_blob);

                            assertAllTrue([
                                text_val == ?{ variant = #text("hello") },
                                nat_val == ?{ variant = #nat(123) },
                                int_val == ?{ variant = #int(-123) },

                                float_val == ?{ variant = #float(-1.23) },
                                bool_val == ?{ variant = #bool(true) },
                                record_val == ?{
                                    variant = #record({ site = "github" });
                                },
                                user_val == ?{
                                    variant = #user({
                                        name = "John";
                                        msg = "Hello World";
                                    });
                                },
                                array_val == ?{ variant = #array([1, 2, 3]) },

                            ]);
                        },
                    ),
                ],
            ),
            describe(
                "motoko toText",
                [
                    it(
                        "single record",
                        do {

                            let info : User = {
                                msg = "Hello World";
                                name = "John";
                            };

                            let blob = to_candid (info);
                            let text = UrlEncoded.toText(blob, ["name", "msg"], null);
                            Debug.print("single record: " #debug_show(text));
                            assertTrue(text == "msg=Hello World&name=John");
                        },
                    ),
                    it(
                        "record with array",
                        do {
                            let users = [
                                {
                                    name = "John";
                                    msg = "Hello World";
                                },
                                {
                                    name = "Jane";
                                    msg = "testing";
                                },
                            ];

                            let blob = to_candid ({ users });

                            let text = UrlEncoded.toText(blob, ["users", "name", "msg"], null);

                            Debug.print("record with array: " #debug_show(text));

                            assertTrue(
                                text == "users[0][msg]=Hello World&users[0][name]=John&users[1][msg]=testing&users[1][name]=Jane"
                            );
                        },
                    ),
                ],
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
