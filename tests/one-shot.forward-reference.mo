// @testmode wasi
import Array "mo:base@0.14.14/Array";
import Blob "mo:base@0.14.14/Blob";
import Debug "mo:base@0.14.14/Debug";
import Iter "mo:base@0.14.14/Iter";
import Principal "mo:base@0.14.14/Principal";
import Text "mo:base@0.14.14/Text";
import TrieMap "mo:base@0.14.14/TrieMap";
import Option "mo:base@0.14.14/Option";

import Arg "mo:candid@2.0.0/Arg";
import Decoder "mo:candid@2.0.0/Decoder";
import Encoder "mo:candid@2.0.0/Encoder";
import Type "mo:candid@2.0.0/Type";
import Value "mo:candid@2.0.0/Value";
import { test; suite } "mo:test";

import Candid "../src/Candid";
import CandidEncoder "../src/Candid/Blob/Encoder.ForwardReference";

type CandidType = Candid.CandidType;

let { toArgs } = CandidEncoder;

let empty_map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

func validate_encoding(candid_values : [Candid.Candid]) : Bool {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, null);

    let #ok(args) = toArgs(candid_values, empty_map);
    let expected = Encoder.encode(args);

    Debug.print("(encoded, expected): " # debug_show (encoded, expected));
    return encoded == expected;
};

func validate_encoding_with_types(candid_values : [Candid.Candid], types : [CandidType]) : Bool {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, ?{ Candid.defaultOptions with types = ?types });

    let #ok(args) = toArgs(candid_values, empty_map);
    let arg_types = Array.map<CandidType, Type.Type>(types, toArgType);

    let arg_types_iter = arg_types.vals();
    let augmented_args = Array.map(
        args,
        func(arg : Arg.Arg) : Arg.Arg {
            let ?arg_type = arg_types_iter.next();

            { arg with type_ = arg_type };
        },
    );

    let expected = Encoder.encode(augmented_args);

    Debug.print("(encoded, expected): " # debug_show (encoded, expected));
    return encoded == expected;
};

func encode(candid_values : [Candid.Candid]) : Blob {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, null);
    return encoded;
};

func encode_with_types(candid_values : [Candid.Candid], types : [CandidType]) : Blob {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, ?{ Candid.defaultOptions with types = ?types });
    return encoded;
};

func equals(encoding : Blob, expected : Blob) : Bool {
    Debug.print("(encoding, expected): " # debug_show (encoding, expected));
    return encoding == expected;
};

func toArgType(candid : CandidType) : (Type.Type) {
    let (arg_type) : (Type.Type) = switch (candid) {
        case (#Nat) (#nat);
        case (#Nat8) (#nat8);
        case (#Nat16) (#nat16);
        case (#Nat32) (#nat32);
        case (#Nat64) (#nat64);

        case (#Int) (#int);
        case (#Int8) (#int8);
        case (#Int16) (#int16);
        case (#Int32) (#int32);
        case (#Int64) (#int64);

        case (#Float) (#float64);

        case (#Bool) (#bool);

        case (#Principal) (#principal);

        case (#Text) (#text);

        case (#Null) (#null_);
        case (#Empty) (#empty);

        case (#Blob(blob)) #vector(#nat8);

        case (#Option(optType)) #opt(toArgType(optType));
        case (#Array(arr_type)) #vector(toArgType(arr_type));

        case (#Record(records) or #Map(records)) #record(
            Array.map(
                records,
                func((key, val) : (Text, CandidType)) : Type.RecordFieldType = {
                    tag = #name(key);
                    type_ = toArgType(val);
                },
            )
        );

        case (#Variant(variants)) #variant(
            Array.map(
                variants,
                func((key, val) : (Text, CandidType)) : Type.RecordFieldType = {
                    tag = #name(key);
                    type_ = toArgType(val);
                },
            )
        );
    };
};

var encoding : Blob = "";
var expected : Blob = "";

suite(
    "One Shot Candid Test",
    func() {

        test(
            "primitives",
            func() {

                assert validate_encoding([]);
                assert validate_encoding([#Nat(0)]);
                assert validate_encoding([#Nat(1)]);
                assert validate_encoding([#Nat(9_223_372_036_854_775_807)]);
                assert validate_encoding([#Nat(18_446_744_073_709_551_615)]); // limited to Nat64 for now
                assert validate_encoding([#Nat(0), #Nat(1), #Nat(18_446_744_073_709_551_615)]);

                assert validate_encoding([#Nat8(0)]);
                assert validate_encoding([#Nat8(1)]);
                assert validate_encoding([#Nat8(255)]);
                assert validate_encoding([#Nat8(0), #Nat8(1), #Nat8(255)]);

                assert validate_encoding([#Nat16(0)]);
                assert validate_encoding([#Nat16(1)]);
                assert validate_encoding([#Nat16(65_535)]);
                assert validate_encoding([#Nat16(0), #Nat16(1), #Nat16(65_535)]);

                assert validate_encoding([#Nat32(0)]);
                assert validate_encoding([#Nat32(1)]);
                assert validate_encoding([#Nat32(4_294_967_295)]);
                assert validate_encoding([#Nat32(0), #Nat32(1), #Nat32(4_294_967_295)]);

                assert validate_encoding([#Nat64(0)]);
                assert validate_encoding([#Nat64(1)]);
                assert validate_encoding([#Nat64(18_446_744_073_709_551_615)]);
                assert validate_encoding([#Nat64(0), #Nat64(1), #Nat64(18_446_744_073_709_551_615)]);

                assert validate_encoding([#Int(1)]);
                assert validate_encoding([#Int(-1)]);
                assert validate_encoding([#Int(127)]);
                assert validate_encoding([#Int(-127)]);
                assert validate_encoding([#Int(123_456_789)]);
                assert validate_encoding([#Int(-123_456_789)]);
                assert validate_encoding([#Int(2_147_483_647)]);
                assert validate_encoding([#Int(-2_147_483_648)]);
                assert validate_encoding([#Int(9_223_372_036_854_775_807)]); // limited to Int64 for now
                // assert validate_encoding([#Int(-9_223_372_036_854_775_807)]); // fails

                assert validate_encoding([#Int8(1)]);
                assert validate_encoding([#Int8(-1)]);
                assert validate_encoding([#Int8(127)]);
                assert validate_encoding([#Int8(-128)]);

                assert validate_encoding([#Int16(1)]);
                assert validate_encoding([#Int16(-1)]);
                assert validate_encoding([#Int16(32_767)]);
                assert validate_encoding([#Int16(-32_768)]);

                assert validate_encoding([#Int32(1)]);
                assert validate_encoding([#Int32(-1)]);
                assert validate_encoding([#Int32(2_147_483_647)]);
                assert validate_encoding([#Int32(-2_147_483_648)]);

                assert validate_encoding([#Int64(1)]);
                assert validate_encoding([#Int64(-1)]);
                assert validate_encoding([#Int64(9_223_372_036_854_775_807)]);
                assert validate_encoding([#Int64(-9_223_372_036_854_775_808)]);

                assert validate_encoding([#Bool(true)]);
                assert validate_encoding([#Bool(false)]);

                assert validate_encoding([#Null]);
                assert validate_encoding([#Empty]);
                assert validate_encoding([#Text("")]);
                assert validate_encoding([#Text("random text")]);

                assert validate_encoding([#Principal(Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"))]);

                assert validate_encoding([#Float(0.0)]);
                assert validate_encoding([#Float(0.6)]);
                assert validate_encoding([#Float(-0.6)]);
                assert validate_encoding([#Float(1.1), #Float(-1.1)]);
            },
        );

    },
);

suite(
    "compound types",
    func() {
        // test(
        //     "option types",
        //     func() {
        //
        //        encoding := encode([#Option(#Null)]);
        //        expected := to_candid(?null : ?Null);
        //        assert equals(encoding, expected);

        //        encoding := encode([#Option(#Int(6)), #Option(#Int(7))]); // does it reference the same type?
        //        expected := to_candid(?6 : ?Int, ?7 : ?Int);
        //        assert equals(encoding, expected);

        //        encoding := encode([#Option(#Option(#Int(6)))]); // does it reference nested types?
        //        expected := to_candid(?(?6) : ?(?Int));
        //        assert equals(encoding, expected);

        //        encoding := encode([#Option(#Option(#Option(#Null)))]);
        //        expected := to_candid(???null : ???Null);
        //        assert equals(encoding, expected);

        //        encoding := encode([#Option(#Null), #Option(#Option(#Null)), #Option(#Option(#Option(#Null)))]);
        //        expected := to_candid(?null : ?Null, ??null : ??Null, ???null : ???Null);
        //        assert equals(encoding, expected);

        //        encoding := encode([#Option(#Nat(0)), #Option(#Text("random text")), #Option(#Option(#Option(#Option(#Option(#Option(#Option(#Text("nested option"))))))))]);
        //        expected := to_candid(?0 : ?Nat, ?"random text" : ?Text, ???????("nested option") : ???????Text);
        //        assert equals(encoding, expected);

        //        // test early null terminated option types
        //        encoding := encode_with_types([#Null], [#Option(#Int)]); // can't express null as the result of an option over the primitive null type without specifying the type
        //        expected := to_candid(null : ?Int);
        //        assert equals(encoding, expected);

        //        encoding := encode_with_types([#Option(#Null)], [#Option(#Option(#Option(#Text)))]);
        //        expected := to_candid(?null : ???Text);
        //        assert equals(encoding, expected);
        //     },
        // );

        test(
            "array types",
            func() {

                encoding := encode([#Array([])]); // transpiles to [#Array(#Empty)]
                expected := to_candid ([] : [None]);
                assert equals(encoding, expected);

                encoding := encode_with_types([#Array([])], [#Array(#Nat)]);
                expected := to_candid ([] : [Nat]);
                assert equals(encoding, expected);

                encoding := encode([#Array([#Nat(0)])]);
                expected := to_candid ([0] : [Nat]);
                assert equals(encoding, expected);

                encoding := encode([#Array([#Nat(0), #Nat(1), #Nat(2)])]);
                expected := to_candid ([0, 1, 2] : [Nat]);
                assert equals(encoding, expected);

                // encoding := encode([#Array([#Option(#Int(6)), #Option(#Int(7)), #Null])]);
                // expected := to_candid([?6, ?7, null] : [?Int]);
                // assert equals(encoding, expected);

                encoding := encode([#Array([#Array([#Nat(0)])])]); // nested array
                expected := to_candid ([[0]] : [[Nat]]);
                assert equals(encoding, expected);

                encoding := encode([#Array([#Array([#Array([#Nat(0)]), #Array([#Nat(1)])])])]);
                expected := to_candid ([[[0], [1]]] : [[[Nat]]]);
                assert equals(encoding, expected);

                encoding := encode([#Array([#Array([#Array([#Array([#Nat(0)])])])])]);
                expected := to_candid ([[[[0]]]] : [[[[Nat]]]]);
                assert equals(encoding, expected);

                // equivalent motoko type -> [?[?[Nat]]]
                // encoding := encode([
                //     #Array([
                //         #Option(#Array([#Option(#Array([#Nat(0)])), #Null])),
                //         #Null,
                //     ])
                // ]);
                // expected := to_candid([?[?[0], null], null] : [?[?[Nat]]]);
                // assert equals(encoding, expected);

                // infered types test by switching #Option(#Null) to first element
                // encoding := encode([
                //     #Array([
                //         #Null,
                //         #Option(#Array([#Null, #Option(#Array([#Text("random")]))])),
                //     ])
                // ]);
                // expected := to_candid([null, ?[null, ?["random"]] ] : [?[?[Text]]]);
                // assert equals(encoding, expected);

            },
        );

        test(
            "record types",
            func() {
                encoding := encode([#Record([])]);
                expected := to_candid ({});
                assert equals(encoding, expected);

                encoding := encode([#Record([("a", #Nat(0))])]);
                expected := to_candid ({ a = 0 });
                assert equals(encoding, expected);

                // the library encoding no longer matches with to_candid's encoding, the sequences are in different order but the result is the same
                // so the testing method is switched to compare their motoko representations
                encoding := encode([#Record([("a", #Nat(0)), ("b", #Int(1)), ("c", #Text("random"))])]);
                expected := to_candid ({ a = 0; b = (1 : Int); c = "random" });
                assert equals(encoding, expected);

                // encoding := encode([#Record([("a", #Option(#Text("random"))), ("b", #Nat(1))])]);
                // expected := to_candid({a = ?"random"; b = 1});
                // assert equals(encoding, expected);
                // assert from_candid(encoding) : ?({a: ?Text; b: Nat}) == ?({a = ?"random"; b = 1});

                // encoding := encode([#Record([("a", #Nat(1)), ("b", #Option(#Text("random")))])]);
                // expected := to_candid({a = 1; b = ?"random"});
                // assert equals(encoding, expected);
                // assert (from_candid(encoding) : ?({a: Nat; b: ?Text})) == ?({a = 1; b = ?"random"});

                // encoding := encode([#Option(#Text("random")), #Record([("a", #Nat(1)), ("b", #Option(#Text("random")))])]);
                // expected := to_candid(?("random"), {a = 1; b = ?"random"});
                // assert equals(encoding, expected);
                // assert (from_candid(encoding) : ?(?Text, ({a: Nat; b: ?Text}))) == ?(?"random", {a = 1; b = ?"random"});

                encoding := encode([#Record([("int", #Int(28)), ("nums", #Array([#Nat(0), #Nat(1), #Nat(2), #Nat(3)]))])]);
                expected := to_candid ({ nums = [0]; int = (28 : Int) });
                ignore equals(encoding, expected);
                assert (from_candid (encoding) : ?({ nums : [Nat]; int : Int })) == ?({
                    nums = [0, 1, 2, 3];
                    int = 28;
                });

                // encoding := encode([#Record([("nums", #Array([#Nat(0)])), ("opt_text", #Option(#Text("random"))), ("int", #Int(1))])]);
                // expected := to_candid({nums = [0]; opt_text = ?"random"; int = (1: Int)});
                // assert equals(encoding, expected);
                // assert (from_candid(encoding) : ?({nums: [Nat]; opt_text: ?Text; int: Int})) == ?({nums = [0]; opt_text = ?"random"; int = 1});

                // encoding := encode([#Array([#Nat(0)]), #Option(#Text("random")), #Record([("nums", #Array([#Nat(0)])), ("opt_text", #Option(#Text("random"))), ("int", #Int(1))])]);
                // expected := to_candid([0], "random", {nums = [0]; opt_text = ?"random"; int = (1: Int)});
                // assert equals(encoding, expected);
                // assert (from_candid(encoding) : ?([Nat], ?Text, {nums: [Nat]; opt_text: ?Text; int: Int})) == ?([0], ?"random", {nums = [0]; opt_text = ?"random"; int = 1});

                // nested records
                encoding := encode([#Record([("a", #Record([("b", #Nat(0))]))])]);
                expected := to_candid ({ a = { b = 0 } });
                ignore equals(encoding, expected);
                Debug.print(debug_show (from_candid (encoding) : ?({ a : { b : Nat } })));
                assert (from_candid (encoding) : ?({ a : { b : Nat } })) == ?({
                    a = { b = 0 };
                });

                encoding := encode([#Record([("c", #Nat(0))]), #Record([("a", #Record([("b", #Record([("c", #Nat(0))]))]))])]);
                expected := to_candid ({ c = 0 }, { a = { b = { c = 0 } } });
                ignore equals(encoding, expected);
                Debug.print(debug_show (from_candid (encoding) : ?({ c : Nat }, { a : { b : { c : Nat } } })));
                assert (from_candid (encoding) : ?({ c : Nat }, { a : { b : { c : Nat } } })) == ?({ c = 0 }, { a = { b = { c = 0 } } });

                encoding := encode([#Record([("a", #Record([("b", #Record([("c", #Record([("d", #Record([("e", #Nat(0))]))]))]))]))])]);
                expected := to_candid ({ a = { b = { c = { d = { e = 0 } } } } });
                ignore equals(encoding, expected);
                Debug.print(debug_show (from_candid (encoding) : ?({ a : { b : { c : { d : { e : Nat } } } } })));
                assert (from_candid (encoding) : ?({ a : { b : { c : { d : { e : Nat } } } } })) == ?({
                    a = { b = { c = { d = { e = 0 } } } };
                });

                encoding := encode([
                    #Record([
                        ("a", #Array([#Record([("a", #Nat(1))]), #Record([("a", #Nat(2))])])),
                    ])
                ]);
                expected := to_candid ({ a = [{ a = 1 }, { a = 2 }] });
                ignore equals(encoding, expected);
                Debug.print(debug_show (from_candid (encoding) : ?({ a : [{ a : Nat }] })));
                assert (from_candid (encoding) : ?({ a : [{ a : Nat }] })) == ?({
                    a = [{ a = 1 }, { a = 2 }];
                });

                // encoding := encode([
                //     #Record([
                //         ("a", #Array([#Nat(23), #Nat(34)])),
                //         ("b", #Array([#Record([("a", #Nat(1))]), #Record([("a", #Nat(2))])])),
                //         ("c", #Array([
                //             #Record([("a", #Nat(1)), ("b", #Text("random"  ))]),
                //             #Record([("a", #Nat(2)), ("b", #Text("random 2"))])
                //         ])),
                //     ])
                // ]);
                // expected := to_candid({a = [23, 34]; b = [{a = 1}, {a = 2}]; c = [{a = 1; b = "random"}, {a = 2; b = "random 2"}]});
                // ignore equals(encoding, expected);
                // Debug.print(debug_show (from_candid(encoding) : ?({a: [Nat]; b: [{a: Nat}]; c: [{a: Nat; b: Text}]}));
                // assert (from_candid(encoding) : ?({a: [Nat]; b: [{a: Nat}]; c: [{a: Nat; b: Text}]})) == ?({a = [23, 34]; b = [{a = 1}, {a = 2}]; c = [{a = 1; b = "random"}, {a = 2; b = "random 2"}]});

                //encoding := encode([
                //    #Option(#Record([("b", #Nat(0))])),
                //    #Record([
                //        ("a", #Option(#Record([("b", #Nat(0))]))),
                //        ("b", #Array([#Option(#Record([("b", #Array([#Option(#Record([("b", #Nat(0))])), #Option(#Record([("b", #Nat(0))]))]))])), #Null])),
                //    ]),
                //]);
                // expected := to_candid(
                //     ?{b = 0},
                //     {a = ?{b = 0}; b = [?{b = [?{b = 0}, ?{b = 0}]}, null]}
                // );
                // assert equals(encoding, expected);
                //assert (
                //    from_candid(encoding) : ?(?{b: Nat}, {a: ?{b: Nat}; b: [?{b: [?{b: Nat}]}]})
                //) == ?(?{b = 0}, {a = ?{b = 0}; b = [?{b = [?{b = 0}, ?{b = 0}]}, null]});

                // tuples
                // assert validate_encoding([#Record([("0", #Nat(0)), ("1", #Nat(1))])]);

            },
        );

        // test(
        //     "variant types",
        //     func() {
        //         // assert validate_encoding([#Variant("nat", #Nat(21))]);
        //         // assert validate_encoding([#Variant("opt_int", #Option(#Int(21)))]);

        //         // type V = {
        //         //     #nat : Nat;
        //         //     #opt_int : ?Int;
        //         //     // #texts: [Text];
        //         //     // #record: {a: Nat};
        //         // };

        //         // var encoding = (encode([#Variant(("nat", #Nat(1)))], ?[#Variant([("nat", #Nat), ("opt_int", #Option(#Int)), ("texts", #Array(#Text)), ("record", #Record([("a", #Nat)]))])]));
        //         // var expected = (to_candid (#nat(1) : V));

        //         // Debug.print(debug_show (encoding, expected));
        //         // assert (from_candid(expected) : ?V) == ?(#nat(1));

        //         // assert validate_encoding_with_types([#Variant("nat", #Nat(21))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int))])]);
        //         // assert validate_encoding_with_types([#Variant("opt_int", #Option(#Int(21)))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int))])]);

        //         // // fails in mo:motoko_candid lib Encoder
        //         // // assert validate_encoding_with_types([#Variant("nat", #Nat(21))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int)), ("texts", #Array(#Text)),
        //         // // ("record", #Record([("a", #Nat)]))
        //         // // ])]);

        //     },
        // );
    },
);
