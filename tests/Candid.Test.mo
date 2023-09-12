// @testmode wasi
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

import ActorSpec "./utils/ActorSpec";

import Serde "../src";
import Candid "../src/Candid";
import Encoder "../src/Candid/Blob/Encoder";

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

type Candid = Candid.Candid;

let success = run([
    describe(
        "Candid",
        [
            describe(
                "decode()",
                [
                    it(
                        "find intended type of nested arrays with different types (null, empty, other_types)",
                        do {
                            type Permission = {
                                #read : [Text];
                                #write : [Text];
                                #read_all : ();
                                #write_all : ();
                                #admin : ();
                            };

                            let PermissionKeys = ["read", "write", "read_all", "write_all", "admin"];

                            type User = {
                                name : Text;
                                age : Nat;
                                permission : Permission;
                            };

                            let UserKeys = ["name", "age", "permission"];

                            type Record = {
                                group : Text;
                                users : ?[User];
                            };

                            let RecordKeys = ["group", "users"];

                            let admin_record : Record = {
                                group = "admins";
                                users = ?[
                                    {
                                        name = "John";
                                        age = 32;
                                        permission = #admin;
                                    },
                                ];
                            };

                            let user_record : Record = {
                                group = "users";
                                users = ?[
                                    {
                                        name = "Ali";
                                        age = 28;
                                        permission = #read_all;
                                    },
                                    {
                                        name = "James";
                                        age = 40;
                                        permission = #write_all;
                                    },
                                ];
                            };

                            let empty_record : Record = {
                                group = "empty";
                                users = ?[];
                            };

                            let null_record : Record = {
                                group = "null";
                                users = null;
                            };

                            let base_record : Record = {
                                group = "base";
                                users = ?[
                                    {
                                        name = "Henry";
                                        age = 32;
                                        permission = #read(["posts", "comments"]);
                                    },
                                    {
                                        name = "Steven";
                                        age = 32;
                                        permission = #write(["posts", "comments"]);
                                    },
                                ];
                            };

                            let records : [Record] = [null_record, empty_record, admin_record, user_record, base_record];
                            let blob = to_candid(records);
                            let #ok(candid) = Candid.decode(blob, Serde.concatKeys([PermissionKeys, UserKeys, RecordKeys]), null);

                            candid == [#Array([
                                #Record([
                                    ("group", #Text("null")),
                                    ("users", #Option(#Null)),
                                ]),
                                #Record([
                                    ("group", #Text("empty")),
                                    ("users", #Option(#Array([]))),
                                ]),
                                #Record([
                                    ("group", #Text("admins")),
                                    ("users", #Option(#Array([
                                        #Record([
                                            ("age", #Nat(32)),
                                            ("name", #Text("John")),
                                            ("permission", #Variant("admin", #Null)),
                                        ]),
                                    ]))),
                                ]),
                                #Record([
                                    ("group", #Text("users")),
                                    ("users", #Option(#Array([
                                        #Record([
                                            ("age", #Nat(28)),
                                            ("name", #Text("Ali")),
                                            ("permission", #Variant("read_all", #Null)),
                                        ]),
                                        #Record([
                                            ("age", #Nat(40)),
                                            ("name", #Text("James")),
                                            ("permission", #Variant("write_all", #Null)),
                                        ]),
                                    ]))),
                                ]),
                                #Record([
                                    ("group", #Text("base")),
                                    ("users", #Option(#Array([
                                        #Record([
                                            ("age", #Nat(32)),
                                            ("name", #Text("Henry")),
                                            ("permission", #Variant("read", #Array([#Text("posts"), #Text("comments")]))),
                                        ]),
                                        #Record([
                                            ("age", #Nat(32)),
                                            ("name", #Text("Steven")),
                                            ("permission", #Variant("write", #Array([#Text("posts"), #Text("comments")]))),
                                        ]),
                                    ]))),
                                ]),
                            ])]
                        },
                    ),
                    it(
                        "duplicate compound types in record",
                        do {
                            type User = {
                                name : Text;
                                age : Nat;
                            };

                            let user_james = {
                                name = "James";
                                age = 23;
                            };

                            let user_steven = {
                                name = "Steven";
                                age = 32;
                            };

                            type Record = {
                                first : User;
                                second : User;
                            };

                            let record = {
                                first = user_james;
                                second = user_steven;
                            };

                            let record_blob = to_candid (record);
                            let candid = Candid.decode(record_blob, ["first", "second", "name", "age"], null);

                            candid == #ok([
                                #Record([
                                    ("first", #Record([("age", #Nat(23)), ("name", #Text("James"))])),
                                    ("second", #Record([("age", #Nat(32)), ("name", #Text("Steven"))])),
                                ]),
                            ]);

                        },
                    ),
                    it(
                        "recursive types",
                        do {
                            type RecursiveType = {
                                user : Text;
                                next : ?RecursiveType;
                            };

                            let rust : RecursiveType = {
                                user = "rust";
                                next = null;
                            };

                            let typescript : RecursiveType = {
                                user = "typescript";
                                next = ?rust;
                            };

                            let motoko : RecursiveType = {
                                user = "motoko";
                                next = ?typescript;
                            };

                            let blob = to_candid (motoko);
                            let candid = Candid.decode(blob, ["next", "user"], null);

                            let candid_rust = #Record([("next", #Option(#Null)), ("user", #Text("rust"))]);
                            let candid_typescript = #Record([("next", #Option(candid_rust)), ("user", #Text("typescript"))]);
                            let candid_motoko = #Record([("next", #Option(candid_typescript)), ("user", #Text("motoko"))]);

                            candid == #ok([candid_motoko]);
                        },
                    ),
                    it(
                        "renaming keys",
                        do {
                            let motoko = [{ name = "candid"; arr = [1, 2, 3, 4] }, { name = "motoko"; arr = [5, 6, 7, 8] }, { name = "rust"; arr = [9, 10, 11, 12] }];
                            let blob = to_candid (motoko);
                            let options = {
                                renameKeys = [("arr", "array"), ("name", "username")];
                            };
                            let candid = Candid.decode(blob, ["name", "arr"], ?options);

                            candid == #ok([
                                #Array([
                                    #Record([
                                        ("array", #Array([#Nat(1), #Nat(2), #Nat(3), #Nat(4)])),
                                        ("username", #Text("candid")),
                                    ]),
                                    #Record([
                                        ("array", #Array([#Nat(5), #Nat(6), #Nat(7), #Nat(8)])),
                                        ("username", #Text("motoko")),
                                    ]),
                                    #Record([
                                        ("array", #Array([#Nat(9), #Nat(10), #Nat(11), #Nat(12)])),
                                        ("username", #Text("rust")),
                                    ]),
                                ])
                            ]);
                        },
                    ),
                    it(
                        "record type: {name: Text}",
                        do {
                            let motoko = { name = "candid" };
                            let blob = to_candid (motoko);
                            let candid = Candid.decode(blob, ["name"], null);

                            candid == #ok([#Record([("name", #Text("candid"))])]);
                        },
                    ),
                    it(
                        "array: [1, 2, 3, 4]",
                        do {
                            let arr = [1, 2, 3, 4];
                            let blob = to_candid (arr);
                            let candid = Candid.decode(blob, [], null);

                            candid == #ok([#Array([#Nat(1), #Nat(2), #Nat(3), #Nat(4)])]);
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
                                Candid.decode(to_candid (arr2), [], null) == #ok([
                                    #Array([
                                        #Array([#Nat(1), #Nat(2), #Nat(3), #Nat(4)]),
                                        #Array([#Nat(5), #Nat(6), #Nat(7), #Nat(8)]),
                                        #Array([#Nat(9), #Nat(10), #Nat(11)]),
                                    ])
                                ]),
                                Candid.decode(to_candid (arr3), [], null) == #ok([
                                    #Array([
                                        #Array([#Array([#Text("hello"), #Text("world")]), #Array([#Text("foo"), #Text("bar")])]),
                                        #Array([#Array([#Text("hello"), #Text("world")]), #Array([#Text("foo"), #Text("bar")])]),
                                        #Array([#Array([#Text("hello"), #Text("world")]), #Array([#Text("foo"), #Text("bar")])]),
                                    ])
                                ]),
                            ]);
                        },
                    ),
                    it(
                        "blob and [Nat8] types",
                        do {
                            let motoko_blob = Blob.fromArray([1, 2, 3, 4]);
                            let motoko_array : [Nat8] = [1, 2, 3, 4];

                            let bytes_array = to_candid (motoko_blob);
                            let bytes_blob = to_candid (motoko_blob);

                            let candid_array = Candid.decode(bytes_array, [], null);
                            let candid_blob = Candid.decode(bytes_blob, [], null);

                            assertAllTrue([
                                // All [Nat8] types are decoded as #Blob
                                candid_array != #ok([#Array([#Nat8(1), #Nat8(2), #Nat8(3), #Nat8(4)])]),
                                candid_array == #ok([#Blob(motoko_blob)]),
                                candid_blob == #ok([#Blob(motoko_blob)]),
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

                            let text_candid = Candid.decode(text_blob, ["text"], null);
                            let nat_candid = Candid.decode(nat_blob, ["nat"], null);
                            let bool_candid = Candid.decode(bool_blob, ["bool"], null);
                            let record_candid = Candid.decode(record_blob, ["record", "site"], null);
                            let array_candid = Candid.decode(array_blob, ["array"], null);

                            assertAllTrue([
                                text_candid == #ok([#Variant("text", #Text("hello"))]),
                                nat_candid == #ok([#Variant("nat", #Nat(123))]),
                                bool_candid == #ok([#Variant("bool", #Bool(true))]),
                                record_candid == #ok([#Variant("record", #Record([("site", #Text("github"))]))]),
                                array_candid == #ok([#Variant("array", #Array([#Nat(1), #Nat(2), #Nat(3)]))]),
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
                            let candid = Candid.decode(blob, record_keys, null);

                            candid == #ok([
                                #Array([
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
                        "find intended type of nested arrays with different types (null, empty, other_types)",
                        do {
                            type Permission = {
                                #read : [Text];
                                #write : [Text];
                                #read_all : ();
                                #write_all : ();
                                #admin : ();
                            };

                            type User = {
                                name : Text;
                                age : Nat;
                                permission : Permission;
                            };

                            type Record = {
                                group : Text;
                                users : ?[User];
                            };

                            let admin_record : Record = {
                                group = "admins";
                                users = ?[
                                    {
                                        name = "John";
                                        age = 32;
                                        permission = #admin;
                                    },
                                ];
                            };

                            let admin_record_candid: Candid = #Record([
                                ("group", #Text("admins")),
                                ("users", #Option(#Array([
                                    #Record([
                                        ("age", #Nat(32)),
                                        ("name", #Text("John")),
                                        ("permission", #Variant("admin", #Null)),
                                    ]),
                                ]))),
                            ]);

                            let user_record : Record = {
                                group = "users";
                                users = ?[
                                    {
                                        name = "Ali";
                                        age = 28;
                                        permission = #read_all;
                                    },
                                    {
                                        name = "James";
                                        age = 40;
                                        permission = #write_all;
                                    },
                                ];
                            };

                            let user_record_candid : Candid = #Record([
                                ("group", #Text("users")),
                                ("users", #Option(#Array([
                                    #Record([
                                        ("age", #Nat(28)),
                                        ("name", #Text("Ali")),
                                        ("permission", #Variant("read_all", #Null)),
                                    ]),
                                    #Record([
                                        ("age", #Nat(40)),
                                        ("name", #Text("James")),
                                        ("permission", #Variant("write_all", #Null)),
                                    ]),
                                ]))),
                            ]);

                            let empty_record : Record = {
                                group = "empty";
                                users = ?[];
                            };

                            let empty_record_candid : Candid = #Record([
                                ("group", #Text("empty")),
                                ("users", #Option(#Array([]))),
                            ]);

                            let null_record : Record = {
                                group = "null";
                                users = null;
                            };

                            let null_record_candid : Candid = #Record([
                                ("group", #Text("null")),
                                ("users", #Option(#Null)),
                            ]);

                            let base_record : Record = {
                                group = "base";
                                users = ?[
                                    {
                                        name = "Henry";
                                        age = 32;
                                        permission = #read(["posts", "comments"]);
                                    },
                                    {
                                        name = "Steven";
                                        age = 32;
                                        permission = #write(["posts", "comments"]);
                                    },
                                ];
                            };

                            let base_record_candid : Candid = #Record([
                                ("group", #Text("base")),
                                ("users", #Option(#Array([
                                    #Record([
                                        ("age", #Nat(32)),
                                        ("name", #Text("Henry")),
                                        ("permission", #Variant("read", #Array([#Text("posts"), #Text("comments")]))),
                                    ]),
                                    #Record([
                                        ("age", #Nat(32)),
                                        ("name", #Text("Steven")),
                                        ("permission", #Variant("write", #Array([#Text("posts"), #Text("comments")]))),
                                    ]),
                                ]))),
                            ]);

                            let records : Candid = #Array([
                                null_record_candid, 
                                empty_record_candid, 
                                admin_record_candid, 
                                user_record_candid, 
                                base_record_candid
                            ]);

                            let #ok(blob) = Candid.encodeOne(records, null);
                            let motoko : ?[Record] = from_candid(blob);
                            
                            motoko == ?[
                                null_record, 
                                empty_record, 
                                admin_record, 
                                user_record, 
                                base_record
                            ];

                        },
                    ),
                    it(
                        "renaming keys",
                        do {
                            let candid : Candid = #Array([
                                #Record([
                                    ("array", #Array([#Nat(1), #Nat(2), #Nat(3), #Nat(4)])),
                                    ("name", #Text("candid")),
                                ]),
                                #Record([
                                    ("array", #Array([#Nat(5), #Nat(6), #Nat(7), #Nat(8)])),
                                    ("name", #Text("motoko")),
                                ]),
                                #Record([
                                    ("array", #Array([#Nat(9), #Nat(10), #Nat(11), #Nat(12)])),
                                    ("name", #Text("rust")),
                                ]),
                            ]);

                            type Data = {
                                language : Text;
                                daily_downloads : [Nat];
                            };

                            let options = {
                                renameKeys = [("array", "daily_downloads"), ("name", "language")];
                            };
                            let #ok(blob) = Candid.encodeOne(candid, ?options);
                            let motoko : ?[Data] = from_candid (blob);
                            // true
                            motoko == ?[{ language = "candid"; daily_downloads = [1, 2, 3, 4] }, { language = "motoko"; daily_downloads = [5, 6, 7, 8] }, { language = "rust"; daily_downloads = [9, 10, 11, 12] }];
                        },
                    ),
                    it(
                        "record type {name: Text}",
                        do {
                            let candid = #Record([("name", #Text("candid"))]);
                            type User = {
                                name : Text;
                            };

                            let #ok(blob) = Candid.encodeOne(candid, null);
                            let user : ?User = from_candid (blob);

                            user == ?{ name = "candid" };
                        },
                    ),
                    it(
                        "multi-dimensional arrays",
                        do {
                            let arr2 : Candid = #Array([
                                #Array([#Nat(1), #Nat(2), #Nat(3), #Nat(4)]),
                                #Array([#Nat(5), #Nat(6), #Nat(7), #Nat(8)]),
                                #Array([#Nat(9), #Nat(10), #Nat(11)]),
                            ]);

                            let arr3 : Candid = #Array([
                                #Array([#Array([#Text("hello"), #Text("world")]), #Array([#Text("foo"), #Text("bar")])]),
                                #Array([#Array([#Text("hello"), #Text("world")]), #Array([#Text("foo"), #Text("bar")])]),
                                #Array([#Array([#Text("hello"), #Text("world")]), #Array([#Text("foo"), #Text("bar")])]),
                            ]);

                            let #ok(arr2_blob) = Candid.encodeOne(arr2, null);
                            let #ok(arr3_blob) = Candid.encodeOne(arr3, null);

                            let arr2_encoded : ?[[Nat]] = from_candid (arr2_blob);
                            let arr3_encoded : ?[[[Text]]] = from_candid (arr3_blob);

                            assertAllTrue([
                                arr2_encoded == ?[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]],
                                arr3_encoded == ?[
                                    [["hello", "world"], ["foo", "bar"]],
                                    [["hello", "world"], ["foo", "bar"]],
                                    [["hello", "world"], ["foo", "bar"]],
                                ],
                            ]);
                        },
                    ),
                    it(
                        "blob and [Nat8] type",
                        do {
                            let motoko_blob = Blob.fromArray([1, 2, 3, 4]);

                            let candid_1 = #Array([#Nat8(1 : Nat8), #Nat8(2 : Nat8), #Nat8(3 : Nat8), #Nat8(4 : Nat8)]);
                            let candid_2 = #Blob(motoko_blob);

                            let #ok(serialized_1) = Candid.encodeOne(candid_1, null);
                            let #ok(serialized_2) = Candid.encodeOne(candid_2, null);

                            let blob_1 : ?Blob = from_candid (serialized_1);
                            let blob_2 : ?Blob = from_candid (serialized_2);

                            let bytes_1 : ?[Nat8] = from_candid (serialized_1);
                            let bytes_2 : ?[Nat8] = from_candid (serialized_1);

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

                            let #ok(text_blob) = Candid.encodeOne(text, null);
                            let #ok(nat_blob) = Candid.encodeOne(nat, null);
                            let #ok(bool_blob) = Candid.encodeOne(bool, null);
                            let #ok(record_blob) = Candid.encodeOne(record, null);
                            let #ok(array_blob) = Candid.encodeOne(array, null);

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

                    let #ok(blob) = Candid.encodeOne(candid, null);

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

            describe(
                "fromText()",
                [
                    describe(
                        "parsing Int and Nat formats",
                        [
                            it(
                                "parse \"quoted text\" to #Text",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("( \"\" )") == [#Text("")],
                                        Candid.fromText("( \"hello\" )") == [#Text("hello")],
                                        Candid.fromText("(\"hello world\")") == [#Text("hello world")],
                                        Candid.fromText("(\"1_000_000\")") == [#Text("1_000_000")],
                                    ]);
                                },
                            ),
                            it(
                                "parse blob type",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(blob \"\")") == [#Blob(Blob.fromArray([]))],
                                        Candid.fromText("(blob \"\\AB\\CD\\EF\")") == [#Blob(Blob.fromArray([0xAB, 0xCD, 0xEF]))],
                                        Candid.fromText("(blob \"\\CA\\FF\\FE\")") == [#Blob(Blob.fromArray([0xCA, 0xFF, 0xFE]))],
                                    ]);
                                },
                            ),
                            it(
                                "should parse principal type",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(principal \"aaaaa-aa\")") == [#Principal(Principal.fromText("aaaaa-aa"))],
                                        Candid.fromText("(principal \"w7x7r-cok77-xa\")") == [#Principal(Principal.fromText("w7x7r-cok77-xa"))],
                                    ]);
                                },
                            ),
                            it(
                                "Positive integers to #Nat",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(  1000)") == [#Nat(1000)],
                                        Candid.fromText("(+2000)") == [#Nat(2000)],
                                    ]);
                                },
                            ),
                            it(
                                "Negative integers to #Int",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(-3000)") == [#Int(-3000)],
                                        Candid.fromText("(-4000)") == [#Int(-4000)],
                                    ]);
                                },
                            ),
                            it(
                                "should parse Int/Nats with leading zeroes",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(001)") == [#Nat(1)],
                                        Candid.fromText("((+00123))") == [#Nat(123)],
                                        Candid.fromText("(-0123)") == [#Int(-0123)],
                                    ]);
                                },
                            ),
                            it(
                                "should parse Int/Nat with underscores",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(   1_000)") == [#Nat(1000)],
                                        Candid.fromText("(+1_000_000)") == [#Nat(1000000)],

                                        Candid.fromText("(-1_000   )") == [#Int(-1000)],
                                        Candid.fromText("((-1_000_000))") == [#Int(-1000000)],
                                    ]);
                                },
                            ),
                            it(
                                "should parse Int/Nat in hex format",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(0x10)") == [#Nat(16)],
                                        Candid.fromText("(0xdead_beef)") == [#Nat(3_735_928_559)],
                                        Candid.fromText("(0xDEAD_BEEF)") == [#Nat(3_735_928_559)],

                                        Candid.fromText("(+0xa1_b2)") == [#Nat(41_394)],
                                        Candid.fromText("(-0xA1_B2)") == [#Int(-41_394)],

                                        Candid.fromText("(-0xABC_def)") == [#Int(-11_259_375)],
                                    ]);
                                },
                            ),
                            it(
                                "should parse types with nested brackets",
                                do {
                                    Candid.fromText("( ( ( ( 100_000 ) ) ) )") == [#Nat(100_000)];
                                },
                            ),
                            it(
                                "should parse 'opt' type",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(opt 100)") == [#Option(#Nat(100))],
                                        Candid.fromText("(opt null)") == [#Option(#Null)],
                                        Candid.fromText("(opt (-0xdead_beef))") == [#Option(#Int(-3_735_928_559))],
                                        Candid.fromText("(opt \"hello\")") == [#Option(#Text("hello"))],
                                        Candid.fromText("(opt true)") == [#Option(#Bool(true))],
                                        Candid.fromText("(opt (blob \"\\AB\\CD\\EF\\12\"))") == [#Option(#Blob(Blob.fromArray([0xAB, 0xCD, 0xEF, 0x12])))],
                                        Candid.fromText("(opt (principal \"w7x7r-cok77-xa\"))") == [#Option(#Principal(Principal.fromText("w7x7r-cok77-xa")))],
                                    ]);
                                },
                            ),
                            describe(
                                "should parse 'vec' type to #Array",
                                [
                                    it(
                                        "parse different element types",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("(vec {})") == [#Array([])],
                                                Candid.fromText("(vec { 100; 200; 0xAB })") == [#Array([#Nat(100), #Nat(200), #Nat(0xAB)])],
                                                Candid.fromText("(vec { \"hello\"; \"world\"; })") == [#Array([#Text("hello"), #Text("world")])],
                                                Candid.fromText("(vec { true; false })") == [#Array([#Bool(true), #Bool(false)])],
                                                Candid.fromText("(vec { blob \"\\AB\\CD\"; blob \"\\EF\\12\" })") == [#Array([#Blob(Blob.fromArray([0xAB, 0xCD])), #Blob(Blob.fromArray([0xEF, 0x12]))])],
                                                Candid.fromText("(vec { principal \"w7x7r-cok77-xa\"; principal \"aaaaa-aa\"; })") == [#Array([#Principal(Principal.fromText("w7x7r-cok77-xa")), #Principal(Principal.fromText("aaaaa-aa"))])],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "parse nested array",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("(vec { vec { 100; 200; 0xAB }; vec { 100; 200; 0xAB } })") == [#Array([#Array([#Nat(100), #Nat(200), #Nat(0xAB)]), #Array([#Nat(100), #Nat(200), #Nat(0xAB)])])],

                                                Candid.fromText("(vec { vec { vec { 100; 200; 0xAB }; vec { 100; 200; 0xAB } }; vec { vec { 100; 200; 0xAB }; vec { 100; 200; 0xAB } } })") == [#Array([#Array([#Array([#Nat(100), #Nat(200), #Nat(0xAB)]), #Array([#Nat(100), #Nat(200), #Nat(0xAB)])]), #Array([#Array([#Nat(100), #Nat(200), #Nat(0xAB)]), #Array([#Nat(100), #Nat(200), #Nat(0xAB)])])])],
                                            ]);
                                        },
                                    ),
                                ],
                            ),

                            it(
                                "parse record type",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(record {})") == [#Record([])],
                                        Candid.fromText("(record { first_name = \"John\"; second_name = \"Doe\" })") == [#Record([("first_name", #Text("John")), ("second_name", #Text("Doe"))])],
                                        Candid.fromText("(record { \"name with spaces\" = 42; \"unicode, too: ☃\" = true; })") == [#Record([("name with spaces", #Nat(42)), ("unicode, too: ☃", #Bool(true))])],
                                        // nested record
                                        Candid.fromText("(record { first_name = \"John\"; second_name = \"Doe\"; address = record { street = \"Main Street\"; city = \"New York\"; } })") == [#Record([("first_name", #Text("John")), ("second_name", #Text("Doe")), ("address", #Record([("street", #Text("Main Street")), ("city", #Text("New York"))]))])],
                                    ]);
                                },
                            ),
                            it(
                                "parser variant type",
                                do {
                                    assertAllTrue([
                                        Candid.fromText("(variant { ok = \"hello\" })") == [#Variant(("ok", #Text("hello")))],

                                        // variant without a value
                                        Candid.fromText("(variant { \"ok\" })") == [#Variant(("ok", #Null))],

                                        // variant with unicode key
                                        Candid.fromText("(variant { \"unicode, too: ☃\" = \"hello\" })") == [#Variant(("unicode, too: ☃", #Text("hello")))],
                                        Candid.fromText("(variant { \"☃\" })") == [#Variant(("☃", #Null))],

                                        // variant with record value
                                        Candid.fromText("(variant { ok = record { \"first name\" = \"John\"; second_name = \"Doe\" } })") == [#Variant(("ok", #Record([("first name", #Text("John")), ("second_name", #Text("Doe"))])))],

                                        // variant with array value
                                        Candid.fromText("(variant { ok = vec { 100; 200; 0xAB } })") == [#Variant(("ok", #Array([#Nat(100), #Nat(200), #Nat(0xAB)])))],

                                        // variant with variant value
                                        Candid.fromText("(variant { ok = variant { status = \"active\" } })") == [#Variant(("ok", #Variant(("status", #Text("active")))))],

                                    ]);
                                },
                            ),

                            describe(
                                "should parse NatX types with type annotations",
                                [
                                    it(
                                        "Nat8",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("(100 : nat8)") == [#Nat8(100 : Nat8)],
                                                Candid.fromText("(00123:nat8)") == [#Nat8(123 : Nat8)],
                                                Candid.fromText("(1_2_3 : nat8)") == [#Nat8(123 : Nat8)],
                                                Candid.fromText("(0xA1 : nat8)") == [#Nat8(161 : Nat8)],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "Nat16",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("((1000 : nat16))") == [#Nat16(1000 : Nat16)],
                                                Candid.fromText("(0061234 : nat16)") == [#Nat16(61234 : Nat16)],
                                                Candid.fromText("(32_892 : nat16)") == [#Nat16(32_892 : Nat16)],
                                                Candid.fromText("(0xBEEF : nat16)") == [#Nat16(48_879 : Nat16)],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "Nat32",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("((1_000_000 : nat32))") == [#Nat32(1_000_000 : Nat32)],
                                                Candid.fromText("(0xdead_beef : nat32)") == [#Nat32(3_735_928_559 : Nat32)],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "Nat64",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("((100_000_000_000 : nat64))") == [#Nat64(100_000_000_000 : Nat64)],
                                                Candid.fromText("(0xdead_beef_1234 : nat64)") == [#Nat64(244_837_814_047_284 : Nat64)],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "Nat",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("((100_000_000_000 : nat))") == [#Nat(100_000_000_000)],
                                                Candid.fromText("(0xdead_beef_1234 : nat)") == [#Nat(244_837_814_047_284)],
                                            ]);
                                        },
                                    ),
                                ],
                            ),
                            describe(
                                "should parse IntX types with type annotations",
                                [
                                    it(
                                        "Int8",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("((+100 : int8))") == [#Int8(100 : Int8)],
                                                Candid.fromText("(-00123:int8)") == [#Int8(-123 : Int8)],
                                                Candid.fromText("(-1_2_3 : int8)") == [#Int8(-123 : Int8)],
                                                Candid.fromText("(-0x7A : int8)") == [#Int8(-122 : Int8)],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "Int16",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("((+1000 : int16))") == [#Int16(1000 : Int16)],
                                                Candid.fromText("(+0031234 : int16)") == [#Int16(31234 : Int16)],
                                                Candid.fromText("(-31_234 : int16)") == [#Int16(-31_234 : Int16)],
                                                Candid.fromText("(-0x7A_BC : int16)") == [#Int16(-31_420 : Int16)],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "Int32",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("((+1_000_000 : int32))") == [#Int32(1_000_000 : Int32)],
                                                Candid.fromText("(-0xbad_beef : int32)") == [#Int32(-195_935_983 : Int32)],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "Int64",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("(+100_000_000_000 : int64)") == [#Int64(100_000_000_000 : Int64)],
                                                Candid.fromText("((-0xdead_beef_1234 : int64))") == [#Int64(-244_837_814_047_284 : Int64)],
                                            ]);
                                        },
                                    ),
                                    it(
                                        "Int",
                                        do {
                                            assertAllTrue([
                                                Candid.fromText("(+100_000_000_000 : int)") == [#Int(100_000_000_000)],
                                                Candid.fromText("((-0xdead_beef_1234 : int))") == [#Int(-244_837_814_047_284)],
                                            ]);
                                        },
                                    ),
                                ],
                            ),

                        ],
                    ),
                ],
            ),
            it(
                "toText() should parse candid text",

                do {
                    let candid = [
                        Candid.toText([#Nat(100)]),
                        Candid.toText([#Nat8(200 : Nat8)]),
                        Candid.toText([#Nat16(300 : Nat16)]),
                        Candid.toText([#Nat32(400 : Nat32)]),
                        Candid.toText([#Nat64(500 : Nat64)]),

                        Candid.toText([#Int(600)]),
                        Candid.toText([#Int8(-70 : Int8)]),
                        Candid.toText([#Int16(800 : Int16)]),
                        Candid.toText([#Int32(-900 : Int32)]),
                        Candid.toText([#Int64(1000 : Int64)]),

                        Candid.toText([#Nat8(100 : Nat8), #Int(-200)]),

                        Candid.toText([#Text("hello")]),
                        Candid.toText([#Record([("name", #Text("John")), ("age", #Nat(30))])]),
                        Candid.toText([#Array([#Nat((100))])]),
                        Candid.toText([#Variant(("email", #Option(#Text("example@gmail.com"))))]),
                        Candid.toText([#Principal(Principal.fromText("aaaaa-aa"))]),
                        Candid.toText([#Nat(100), #Text("hello"), #Record([("name", #Text("John")), ("age", #Nat(30))])]),
                    ];

                    candid == [
                        "(100)",
                        "(200 : nat8)",
                        "(300 : nat16)",
                        "(400 : nat32)",
                        "(500 : nat64)",

                        "(600)",
                        "(-70 : int8)",
                        "(800 : int16)",
                        "(-900 : int32)",
                        "(1000 : int64)",

                        "((100 : nat8), -200)",

                        "(\"hello\")",
                        "(record { name = \"John\"; age = 30; })",
                        "(vec { 100; })",
                        "(variant { email = opt (\"example@gmail.com\") })",
                        "(principal \"aaaaa-aa\")",
                        "(100, \"hello\", record { name = \"John\"; age = 30; })",
                    ];
                },
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
