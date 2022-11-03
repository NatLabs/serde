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
                    "encode()",
                    [
                        it(
                            "record type: {name: Text}",
                            do {
                                let motoko = { name = "Tomi" };
                                let blob = to_candid (motoko);
                                let candid = Candid.encode(blob, ["name"]);

                                candid == #Record([("name", #Text("Tomi"))]);
                            },
                        ),
                        it(
                            "array: [1, 2, 3, 4]",
                            do {
                                let arr = [1, 2, 3, 4];
                                let blob = to_candid (arr);
                                let candid = Candid.encode(blob, []);

                                candid == #Vector([#Nat(1), #Nat(2), #Nat(3), #Nat(4)]);
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
                                let candid = Candid.encode(blob, record_keys);

                                candid == #Vector([
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
                    "decode()",
                    [
                        it(
                            "record type {name: Text}",
                            do {
                                let candid = #Record([("name", #Text("Tomi"))]);
                                type User = {
                                    name : Text;
                                };

                                let blob = Candid.decode(candid);
                                let user : ?User = from_candid (blob);

                                user == ?{ name = "Tomi" };
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
