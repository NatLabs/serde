import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import Arg "mo:candid/Arg";
import Decoder "mo:candid/Decoder";
import Encoder "mo:candid/Encoder";
import Type "mo:candid/Type";
import Value "mo:candid/Value";
import { test; suite } "mo:test";

import Candid "../src/Candid";
import CandidEncoder "../src/Candid/Blob/Encoder";

type CandidTypes = Candid.CandidTypes;

let { toArgs } = CandidEncoder;

let empty_map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

func validate_encoding(candid_values : [Candid.Candid]) : Bool {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, null);

    let #ok(args) = toArgs(candid_values, empty_map);
    let expected = Encoder.encode(args);

    Debug.print("(encoded, expected): " # debug_show (encoded, expected));
    return encoded == expected;
};

func validate_encoding_with_types(candid_values : [Candid.Candid], types : [CandidTypes]) : Bool {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, ?{ Candid.defaultOptions with types = ?types });

    let #ok(args) = toArgs(candid_values, empty_map);
    let arg_types = Array.map<CandidTypes, Type.Type>(types, toArgType);

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

func encode(candid_values : [Candid.Candid], types : ?[CandidTypes]) : Blob {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, ?{ Candid.defaultOptions with types });
    return encoded;
};

func toArgType(candid : CandidTypes) : (Type.Type) {
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
                func((key, val) : (Text, CandidTypes)) : Type.RecordFieldType = {
                    tag = #name(key);
                    type_ = toArgType(val);
                },
            )
        );

        case (#Variant(variants)) #variant(
            Array.map(
                variants,
                func((key, val) : (Text, CandidTypes)) : Type.RecordFieldType = {
                    tag = #name(key);
                    type_ = toArgType(val);
                },
            )
        );
    };
};

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
        test(
            "option types",
            func() {

                // todo: test more early null terminated option types
                // Debug.print(debug_show (to_candid (null : ?Int)));
                // Debug.print(debug_show (encode([#Option(#Null)], ?[#Option(#Int)])));
                // assert encode([#Option(#Null)], ?[#Option(#Int)]) == (to_candid (null : ?Int));

                assert validate_encoding([#Option(#Null)]);
                assert validate_encoding([#Option(#Int(6)), #Option(#Int(7))]); // does it reference the same type?
                assert validate_encoding([#Option(#Option(#Int(6)))]);

                assert validate_encoding([#Option(#Option(#Option(#Null)))]);
                assert validate_encoding([#Option(#Null), #Option(#Option(#Null)), #Option(#Option(#Option(#Null)))]);

                assert validate_encoding([#Option(#Nat(0)), #Option(#Text("random text")), #Option(#Option(#Option(#Option(#Option(#Option(#Option(#Option(#Text("nested option")))))))))]);

            },
        );

        test(
            "array types",
            func() {

                assert validate_encoding([#Array([])]); // transpiles to [#Array(#Empty)]
                assert validate_encoding([#Array([#Nat(0)])]);
                assert validate_encoding([#Array([#Nat(0), #Nat(1), #Nat(2)])]);
                assert validate_encoding([#Array([#Option(#Int(6)), #Option(#Int(7)), #Option(#Null)])]);
                assert validate_encoding([#Option(#Int(6)), #Array([#Option(#Int(6)), #Option(#Int(7)), #Option(#Null)])]);

                assert validate_encoding([#Array([#Array([#Nat(0)])])]); // nested array
                assert validate_encoding([#Array([#Array([#Array([#Nat(0)]), #Array([#Nat(1)])])])]);
                assert validate_encoding([#Array([#Array([#Array([#Array([#Nat(0)])])])])]);

                // equivalent motoko type -> [?[?[Nat]]]
                assert validate_encoding([
                    #Array([
                        #Option(#Array([#Option(#Array([#Nat(0)])), #Option(#Null)])),
                        #Option(#Null),
                    ])
                ]);

                // infered types test by switching #Option(#Null) to first element
                assert validate_encoding([
                    #Array([
                        #Option(#Null),
                        #Option(#Array([#Option(#Null), #Option(#Array([#Text("random")]))])),
                    ])
                ]);
            },
        );

        test(
            "record types",
            func() {
                assert validate_encoding([#Record([])]);
                assert validate_encoding([#Record([("a", #Nat(0))])]);
                assert validate_encoding([#Record([("a", #Nat(0)), ("b", #Int(1)), ("c", #Text("random"))])]);

                assert validate_encoding([#Record([("a", #Option(#Text("random"))), ("b", #Nat(1))])]);
                assert validate_encoding([#Record([("a", #Nat(1)), ("b", #Option(#Text("random")))])]);
                assert validate_encoding([#Option(#Text("random")), #Record([("a", #Nat(1)), ("b", #Option(#Text("random")))])]);
                assert validate_encoding([#Record([("nums", #Array([#Nat(0)])), ("int", #Int(1))])]);
                assert validate_encoding([#Record([("nums", #Array([#Nat(0)])), ("opt_text", #Option(#Text("random"))), ("int", #Int(1))])]);
                assert validate_encoding([#Array([#Nat(0)]), #Option(#Text("random")), #Record([("nums", #Array([#Nat(0)])), ("opt_text", #Option(#Text("random"))), ("int", #Int(1))])]);

                // nested records
                assert validate_encoding([#Record([("a", #Record([("b", #Nat(0))]))])]);
                assert validate_encoding([#Record([("c", #Nat(0))]), #Record([("a", #Record([("b", #Record([("c", #Nat(0))]))]))])]);
                assert validate_encoding([#Record([("a", #Record([("b", #Record([("c", #Record([("d", #Record([("e", #Nat(0))]))]))]))]))])]);

                assert validate_encoding([
                    #Option(#Record([("b", #Nat(0))])),
                    #Record([
                        ("a", #Option(#Record([("b", #Nat(0))]))),
                        ("b", #Array([#Option(#Record([("b", #Array([#Option(#Record([("b", #Nat(0))])), #Option(#Record([("b", #Nat(0))]))]))])), #Option(#Null)])),
                    ]),
                ]);

                // tuples 
                // assert validate_encoding([#Record([("0", #Nat(0)), ("1", #Nat(1))])]);

            },
        );

        test(
            "variant types",
            func() {
                // assert validate_encoding([#Variant("nat", #Nat(21))]);
                // assert validate_encoding([#Variant("opt_int", #Option(#Int(21)))]);

                // type V = {
                //     #nat : Nat;
                //     #opt_int : ?Int;
                //     // #texts: [Text];
                //     // #record: {a: Nat};
                // };

                // var encoding = (encode([#Variant(("nat", #Nat(1)))], ?[#Variant([("nat", #Nat), ("opt_int", #Option(#Int)), ("texts", #Array(#Text)), ("record", #Record([("a", #Nat)]))])]));
                // var expected = (to_candid (#nat(1) : V));

                // Debug.print(debug_show (encoding, expected));
                // assert (from_candid(expected) : ?V) == ?(#nat(1));

                // assert validate_encoding_with_types([#Variant("nat", #Nat(21))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int))])]);
                // assert validate_encoding_with_types([#Variant("opt_int", #Option(#Int(21)))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int))])]);
                
                // // fails in mo:motoko_candid lib Encoder
                // // assert validate_encoding_with_types([#Variant("nat", #Nat(21))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int)), ("texts", #Array(#Text)), 
                // // ("record", #Record([("a", #Nat)]))
                // // ])]);


            },
        );
    },
);
