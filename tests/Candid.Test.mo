import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

import Candid "../src/Candid";
import Encoder "../src/Candid/Encoder";

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
                                let motoko = { name = "candid" };
                                let blob = to_candid (motoko);
                                let candid = Candid.decode(blob, ["name"]);

                                candid == #Record([("name", #Text("candid"))]);
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
                            "blob and [Nat8] types",
                            do {
                                let motoko_blob = Blob.fromArray([1, 2, 3, 4]);
                                let motoko_array: [Nat8] = [1, 2, 3, 4];

                                let bytes_array = to_candid (motoko_blob);
                                let bytes_blob = to_candid (motoko_blob);

                                let candid_array = Candid.decode(bytes_array, []);
                                let candid_blob = Candid.decode(bytes_blob, []);

                                assertAllTrue([
                                    // All [Nat8] types are decoded as #Blob
                                    candid_array != #Array([#Nat8(1), #Nat8(2), #Nat8(3), #Nat8(4)]),
                                    candid_array == #Blob(motoko_blob),
                                    candid_blob == #Blob(motoko_blob),
                                ]);
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
                                let candid = #Record([("name", #Text("candid"))]);
                                type User = {
                                    name : Text;
                                };

                                let blob = Candid.encode(candid);
                                let user : ?User = from_candid (blob);

                                user == ?{ name = "candid" };
                            },
                        ),
                        it(
                            "blob and [Nat8] type",
                            do {
                                let motoko_blob = Blob.fromArray([1, 2, 3, 4]);

                                let candid_1 = #Array([#Nat8(1:Nat8), #Nat8(2:Nat8), #Nat8(3:Nat8), #Nat8(4:Nat8)]);
                                let candid_2 = #Blob(motoko_blob);

                                let serialized_1 = Candid.encode(candid_1);
                                let serialized_2 = Candid.encode(candid_2);

                                let blob_1: ?Blob = from_candid(serialized_1);
                                let blob_2: ?Blob = from_candid(serialized_2);

                                let bytes_1: ?[Nat8] = from_candid(serialized_1);
                                let bytes_2: ?[Nat8] = from_candid(serialized_1);

                                assertAllTrue([
                                    blob_1 == ?motoko_blob,
                                    blob_2 == ?motoko_blob,
                                    bytes_1 == ?[1, 2, 3, 4],
                                    bytes_2 == ?[1, 2, 3, 4],
                                ]);
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

                it(
                    "print out args",
                    do {
                        type User = {
                            name : Text;
                            details : {
                                age : Nat;
                                email : ?Text;
                                registered : Bool;
                            };
                        };

                        let candid = #Record([
                            ("name", #Text("candid")),
                            ("details", #Record([("age", #Nat(32)), ("email", #Option(#Text("example@gmail.com"))), ("registered", #Bool(true))])),
                        ]);

                        let blob = Candid.encode(candid);

                        let mo : ?User = from_candid (blob);
                        mo == ?{
                            name = "candid";
                            details = {
                                age = 32;
                                email = ?"example@gmail.com";
                                registered = true;
                            };
                        };
                    },
                ),

                describe("fromText()", [
                    describe("parsing Int and Nat formats", [
                        it("Positive integers to #Nat", do{
                            assertAllTrue([
                                Candid.fromText("  1000") == #Nat(1000),
                                Candid.fromText("(+2000)") == #Nat(2000),
                            ])
                        }),
                        it("Negative integers to #Int", do{
                            assertAllTrue([
                                Candid.fromText("-3000") == #Int(-3000),
                                Candid.fromText("-4000") == #Int(-4000),
                            ])
                        }),
                        it("should parse Int/Nats with leading zeroes", do{
                            assertAllTrue([
                               Candid.fromText("001") == #Nat(1),
                               Candid.fromText("(+00123)") == #Nat(123),
                               Candid.fromText("-0123") == #Int(-0123),
                            ])
                        }),
                        it("should parse Int/Nat with underscores", do {
                            assertAllTrue([
                                Candid.fromText("   1_000") == #Nat(1000),
                                Candid.fromText("+1_000_000") == #Nat(1000000),

                                Candid.fromText("-1_000   ") == #Int(-1000),
                                Candid.fromText("(-1_000_000)") == #Int(-1000000),
                            ])
                        }),
                        it("should parse Int/Nat in hex format", do {
                            assertAllTrue([
                                Candid.fromText("0x10") == #Nat(16),
                                Candid.fromText("0xdead_beef") == #Nat(3_735_928_559),
                                Candid.fromText("0xDEAD_BEEF") == #Nat(3_735_928_559),

                                Candid.fromText("+0xa1_b2") == #Nat(41_394),
                                Candid.fromText("-0xA1_B2") == #Int(-41_394),

                                Candid.fromText("-0xABC_def") == #Int(-11_259_375),
                            ])
                        }),
                    ]),

                    it("should decode candid text", do {
                        let candid =[
                            Candid.fromText("(1000)"),
                            Candid.fromText("(+2000)"),
                            Candid.fromText("(-3000)"),
                        ];

                        candid == [
                            #Nat(1000),
                            #Nat(2000),
                            #Int(-3000),
                        ];
                    }),
                ])
            ],
        ),
    ],
);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
