import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

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

let success = run(
    [
        describe(
            "Candid",
            [
                describe(
                    "decode()",
                    [
                        it(
                            "record type: {name: Text}",
                            do {
                                let motoko = { name = "Tomi" };
                                let blob = to_candid (motoko);
                                let candid = Candid.decode(blob, ["name"]);

                                candid == #Record([("name", #Text("Tomi"))]);
                            },
                        ),
                        it(
                            "array: [1, 2, 3, 4]",
                            do {
                                let arr = [1, 2, 3, 4];
                                let blob = to_candid (arr);
                                let candid = Candid.decode(blob, []);

                                candid == #Array([#Nat(1), #Nat(2), #Nat(3), #Nat(4)]);
                            },
                        ),
                        it(
                            "variant",
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

                                let text_candid = Candid.decode(text_blob, ["text"]);
                                let nat_candid = Candid.decode(nat_blob, ["nat"]);
                                let bool_candid = Candid.decode(bool_blob, ["bool"]);
                                let record_candid = Candid.decode(record_blob, ["record", "site"]);
                                let array_candid = Candid.decode(array_blob, ["array"]);

                                assertAllTrue([
                                    text_candid == #Variant("text", #Text("hello")),
                                    nat_candid == #Variant("nat", #Nat(123)),
                                    bool_candid == #Variant("bool", #Bool(true)),
                                    record_candid == #Variant("record", #Record([("site", #Text("github"))])),
                                    array_candid == #Variant("array", #Array([#Nat(1), #Nat(2), #Nat(3)])),
                                ]);

                            },
                        ),
                        it(
                            "complex type",
                            do {
                                type User = {
                                    name : Text;
                                    age : Nat8;
                                    email : ?Text;
                                    registered : Bool;
                                };
                                let record_keys = ["name", "age", "email", "registered"];
                                let users : [User] = [
                                    {
                                        name = "Henry";
                                        age = 32;
                                        email = null;
                                        registered = false;
                                    },
                                    {
                                        name = "Ali";
                                        age = 28;
                                        email = ?"ali.abdull@gmail.com";
                                        registered = false;
                                    },
                                    {
                                        name = "James";
                                        age = 40;
                                        email = ?"james.bond@gmail.com";
                                        registered = true;
                                    },
                                ];

                                let blob = to_candid (users);
                                let candid = Candid.decode(blob, record_keys);

                                candid == #Array([
                                    #Record([
                                        ("age", #Nat8(32)),
                                        ("email", #Option(#Null)),
                                        ("name", #Text("Henry")),
                                        ("registered", #Bool(false)),
                                    ]),
                                    #Record([
                                        ("age", #Nat8(28)),
                                        ("email", #Option(#Text("ali.abdull@gmail.com"))),
                                        ("name", #Text("Ali")),
                                        ("registered", #Bool(false)),
                                    ]),
                                    #Record([
                                        ("age", #Nat8(40)),
                                        ("email", #Option(#Text("james.bond@gmail.com"))),
                                        ("name", #Text("James")),
                                        ("registered", #Bool(true)),
                                    ]),
                                ]);
                            },
                        ),
                    ],
                ),

                describe(
                    "encode()",
                    [
                        it(
                            "record type {name: Text}",
                            do {
                                let candid = #Record([("name", #Text("Tomi"))]);
                                type User = {
                                    name : Text;
                                };

                                let blob = Candid.encode(candid);
                                let user : ?User = from_candid (blob);

                                user == ?{ name = "Tomi" };
                            },
                        ),
                        it(
                            "variant",
                            do {

                                type Variant = {
                                    #text : Text;
                                    #nat : Nat;
                                    #bool : Bool;
                                    #record : { site : Text };
                                    #array : [Nat];
                                };

                                let text = #Variant("text", #Text("hello"));
                                let nat = #Variant("nat", #Nat(123));
                                let bool = #Variant("bool", #Bool(true));
                                let record = #Variant("record", #Record([("site", #Text("github"))]));
                                let array = #Variant("array", #Array([#Nat(1), #Nat(2), #Nat(3)]));

                                let text_blob = Candid.encode(text);
                                let nat_blob = Candid.encode(nat);
                                let bool_blob = Candid.encode(bool);
                                let record_blob = Candid.encode(record);
                                let array_blob = Candid.encode(array);

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
            ],
        ),
    ],
);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
