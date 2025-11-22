// @testmode wasi
import Debug "mo:base@0.16.0/Debug";
import Iter "mo:base@0.16.0/Iter";

import { test; suite } "mo:test";

import UrlEncoded "../src/UrlEncoded";

type User = {
    name : Text;
    msg : Text;
};

suite(
    "UrlEncoded Pairs",
    func() {
        suite(
            "fromText to motoko",
            func() {
                test(
                    "single record",
                    func() {

                        let blob = switch (UrlEncoded.fromText("msg=Hello World&name=John", null)) {
                            case (#ok(b)) b;
                            case (#err(errorMsg)) Debug.trap(errorMsg);
                        };

                        let res : ?User = from_candid (blob);

                        assert (
                            res == ?{
                                name = "John";
                                msg = "Hello World";
                            }
                        );
                    },
                );
                test(
                    "pairs with empty values",
                    func() {

                        let #ok(unknown_blob) = UrlEncoded.fromText("msg=Hello&name=", null);
                        let #ok(known_blob) = UrlEncoded.fromText("msg=Hello&name=John", null);

                        type UserOptionalName = {
                            name : ?Text;
                            msg : Text;
                        };

                        let unknown_user : ?UserOptionalName = from_candid (unknown_blob);
                        let known_user : ?UserOptionalName = from_candid (known_blob);

                        assert (
                            unknown_user == ?{
                                name = null;
                                msg = "Hello";
                            }
                        );
                        assert (
                            known_user == ?{
                                name = ?"John";
                                msg = "Hello";
                            }
                        );
                    },
                );
                test(
                    "record with array",
                    func() {

                        let text = "users[0][name]=John&users[0][msg]=Hello World&users[1][name]=Jane&users[1][msg]=testing";
                        let #ok(blob) = UrlEncoded.fromText(text, null);

                        let res : ?{ users : [User] } = from_candid (blob);
                        assert (
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
                );
                test(
                    "variant type",
                    func() {
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

                        let #ok(text_blob) = UrlEncoded.fromText(text, null);
                        let #ok(nat_blob) = UrlEncoded.fromText(nat, null);
                        let #ok(int_blob) = UrlEncoded.fromText(int, null);
                        let #ok(float_blob) = UrlEncoded.fromText(float, null);
                        let #ok(bool_blob) = UrlEncoded.fromText(bool, null);
                        let #ok(record_blob) = UrlEncoded.fromText(record, null);
                        let #ok(user_blob) = UrlEncoded.fromText(user, null);
                        let #ok(array_blob) = UrlEncoded.fromText(array, null);

                        let text_val : ?{ variant : Variant } = from_candid (text_blob);
                        let nat_val : ?{ variant : Variant } = from_candid (nat_blob);
                        let int_val : ?{ variant : Variant } = from_candid (int_blob);
                        let float_val : ?{ variant : Variant } = from_candid (float_blob);
                        let bool_val : ?{ variant : Variant } = from_candid (bool_blob);
                        let record_val : ?{ variant : Variant } = from_candid (record_blob);
                        let user_val : ?{ variant : Variant } = from_candid (user_blob);
                        let array_val : ?{ variant : Variant } = from_candid (array_blob);

                        assert (text_val == ?{ variant = #text("hello") });
                        assert (nat_val == ?{ variant = #nat(123) });
                        assert (int_val == ?{ variant = #int(-123) });
                        assert (float_val == ?{ variant = #float(-1.23) });
                        assert (bool_val == ?{ variant = #bool(true) });
                        assert (
                            record_val == ?{
                                variant = #record({ site = "github" });
                            }
                        );
                        assert (
                            user_val == ?{
                                variant = #user({
                                    name = "John";
                                    msg = "Hello World";
                                });
                            }
                        );
                        assert (array_val == ?{ variant = #array([1, 2, 3]) });
                    },
                );
            },
        );
        suite(
            "motoko toText",
            func() {
                test(
                    "single record",
                    func() {

                        let info : User = {
                            msg = "Hello World";
                            name = "John";
                        };

                        let blob = to_candid (info);
                        let text = UrlEncoded.toText(blob, ["name", "msg"], null);
                        Debug.print("single record: " #debug_show (text));
                        assert (text == #ok("msg=Hello World&name=John"));
                    },
                );
                test(
                    "record with array",
                    func() {
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

                        Debug.print("record with array: " #debug_show (text));

                        assert (
                            text == #ok("users[0][msg]=Hello World&users[0][name]=John&users[1][msg]=testing&users[1][name]=Jane")
                        );
                    },
                );
            },
        );
    },
);
