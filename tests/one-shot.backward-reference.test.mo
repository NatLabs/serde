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
import CandidDecoder "../src/Candid/Blob/Decoder";
import { toArgs; toArgType } "../src/libs/motoko_candid/utils";

type CandidType = Candid.CandidType;

let empty_map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

func validate_encoding(candid_values : [Candid.Candid]) : Bool {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, null);

    let #ok(args) = toArgs(candid_values, empty_map);
    let expected = Encoder.encode(args);

    // Debug.print("(encoded, expected): " # debug_show (encoded, expected));
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

    // Debug.print("(encoded, expected): " # debug_show (encoded, expected));
    return encoded == expected;
};

let RecordKeys = ["a", "b", "c", "d", "e"];
func validate_decoding(candid_values: [Candid.Candid]): Bool {
    let #ok(encoded) = Candid.encode(candid_values, null);
    // Debug.print("encoded: " # debug_show encoded);

    let #ok(expected) = CandidDecoder.one_shot(encoded, RecordKeys, null);

    // Debug.print("(decoded, expected): " # debug_show (candid_values, expected));

    candid_values == expected;
};

func validate_decoding_with_types(candid_values: [Candid.Candid], types: [CandidType]): Bool {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, ?{ Candid.defaultOptions with types = ?types });
    // Debug.print("encoded: " # debug_show encoded);

    let #ok(expected) = CandidDecoder.one_shot(encoded, RecordKeys, ?{ Candid.defaultOptions with types = ?types });
    // Debug.print("(decoded, expected): " # debug_show (candid_values, expected));

    candid_values == expected;
};

func encode(candid_values : [Candid.Candid], types : ?[CandidType]) : Blob {
    let #ok(encoded) = CandidEncoder.one_shot(candid_values, ?{ Candid.defaultOptions with types });
    return encoded;
};

suite(
    "One Shot Encoding",
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

        test(
            "option types",
            func() {

                // todo: test more early null terminated option types
                // Debug.print(debug_show (to_candid (null : ?Int)));
                // Debug.print(debug_show (encode([#Option(#Null)], ?[#Option(#Int)])));
                // assert encode([#Option(#Null)], ?[#Option(#Int)]) == (to_candid (null : ?Int));

                assert validate_encoding_with_types([#Option(#Null)], [#Option(#Int)]);
                // assert validate_encoding_with_types([#Null], [#Option(#Int)]);
                assert validate_encoding([#Option(#Int(6)), #Option(#Int(7))]); // does it reference the same type?
                assert validate_encoding([#Option(#Option(#Int(6)))]);

                // assert validate_encoding([#Option(#Option(#Option(#Null)))]);
                // assert validate_encoding([#Option(#Null), #Option(#Option(#Null)), #Option(#Option(#Option(#Null)))]);

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
                assert validate_encoding([#Record([("a", #Array([#Nat(0)])), ("b", #Int(1))])]);
                assert validate_encoding([#Record([("a", #Array([#Nat(0)])), ("b", #Option(#Text("random"))), ("c", #Int(1))])]);
                assert validate_encoding([#Array([#Nat(0)]), #Option(#Text("random")), #Record([("a", #Array([#Nat(0)])), ("b", #Option(#Text("random"))), ("c", #Int(1))])]);

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

                
            },
        );

        test("tuples", func(){
            // assert validate_encoding([#Record([("0", #Nat(0)), ("1", #Nat(1))])]);

            assert validate_encoding([#Tuple([#Nat(0), #Int(1)])]);
            assert validate_encoding([#Tuple([#Nat(0), #Float(1.1), #Text("random"), #Option(#Int(6))])]);
            assert validate_encoding([#Tuple([
                #Array([#Nat(0)]), 
                #Option(#Text("random")), 
                #Record([("a", #Array([#Nat(0)])), ("b", #Option(#Text("random"))), ("c", #Int(1))])
            ])]);
        });

        test(
            "variant types",
            func() {
                assert validate_encoding([#Variant("nat", #Nat(21))]);
                assert validate_encoding([#Variant("opt_int", #Option(#Int(21)))]);

                type V = {
                    #nat : Nat;
                    #opt_int : ?Int;
                    // #texts: [Text];
                    // #record: {a: Nat};
                };

                // var encoding = (encode([#Variant(("nat", #Nat(1)))], ?[#Variant([("nat", #Nat), ("opt_int", #Option(#Int)), ("texts", #Array(#Text)), ("record", #Record([("a", #Nat)]))])]));
                // var expected = (to_candid (#nat(1) : V));

                // Debug.print(debug_show (encoding, expected));
                // assert (from_candid(expected) : ?V) == ?(#nat(1));

                assert validate_encoding_with_types([#Variant("nat", #Nat(21))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int))])]);
                assert validate_encoding_with_types([#Variant("opt_int", #Option(#Int(21)))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int))])]);
                
                // fails in mo:motoko_candid lib Encoder
                // assert validate_encoding_with_types([#Variant("nat", #Nat(21))], [#Variant([("nat", #Nat), ("opt_int", #Option(#Int)), ("texts", #Array(#Text)), 
                // ("record", #Record([("a", #Nat)]))
                // ])]);
            },
        );

    },
);

suite(
    "One Shot Decoding",
    func() {
        test("primitives", func(){
            assert validate_decoding([]);
            assert validate_decoding([#Nat(0)]);
            assert validate_decoding([#Nat(1)]);
            assert validate_decoding([#Nat(9_223_372_036_854_775_807)]);
            assert validate_decoding([#Nat(18_446_744_073_709_551_615)]); // limited to Nat64 for now
            assert validate_decoding([#Nat(0), #Nat(1), #Nat(18_446_744_073_709_551_615)]);

            assert validate_decoding([#Nat8(0)]);
            assert validate_decoding([#Nat8(1)]);
            assert validate_decoding([#Nat8(255)]);
            assert validate_decoding([#Nat8(0), #Nat8(1), #Nat8(255)]);

            assert validate_decoding([#Nat16(0)]);
            assert validate_decoding([#Nat16(1)]);
            assert validate_decoding([#Nat16(65_535)]);
            assert validate_decoding([#Nat16(0), #Nat16(1), #Nat16(65_535)]);

            assert validate_decoding([#Nat32(0)]);
            assert validate_decoding([#Nat32(1)]);
            assert validate_decoding([#Nat32(4_294_967_295)]);
            assert validate_decoding([#Nat32(0), #Nat32(1), #Nat32(4_294_967_295)]);

            assert validate_decoding([#Nat64(0)]);
            assert validate_decoding([#Nat64(1)]);
            assert validate_decoding([#Nat64(18_446_744_073_709_551_615)]);
            assert validate_decoding([#Nat64(0), #Nat64(1), #Nat64(18_446_744_073_709_551_615)]);

            assert validate_decoding([#Int(1)]);
            assert validate_decoding([#Int(-1)]);
            assert validate_decoding([#Int(127)]);
            assert validate_decoding([#Int(-127)]);
            assert validate_decoding([#Int(123_456_789)]);
            assert validate_decoding([#Int(-123_456_789)]);
            assert validate_decoding([#Int(2_147_483_647)]);
            assert validate_decoding([#Int(-2_147_483_648)]);

            assert validate_decoding([#Int8(1)]);
            assert validate_decoding([#Int8(-1)]);
            assert validate_decoding([#Int8(127)]);
            assert validate_decoding([#Int8(-128)]);

            assert validate_decoding([#Int16(1)]);
            assert validate_decoding([#Int16(-1)]);
            assert validate_decoding([#Int16(32_767)]);
            assert validate_decoding([#Int16(-32_768)]);

            assert validate_decoding([#Int32(1)]);
            assert validate_decoding([#Int32(-1)]);
            assert validate_decoding([#Int32(2_147_483_647)]);
            assert validate_decoding([#Int32(-2_147_483_648)]);

            assert validate_decoding([#Int64(1)]);
            assert validate_decoding([#Int64(-1)]);
            assert validate_decoding([#Int64(9_223_372_036_854_775_807)]);
            assert validate_decoding([#Int64(-9_223_372_036_854_775_808)]);

            assert validate_decoding([#Bool(true)]);
            assert validate_decoding([#Bool(false)]);

            assert validate_decoding([#Null]);
            assert validate_decoding([#Empty]);
            assert validate_decoding([#Text("")]);
            assert validate_decoding([#Text("random text")]);

            assert validate_decoding([#Principal(Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"))]);

            assert validate_decoding([#Float(0.0)]);
            assert validate_decoding([#Float(0.6)]);
            assert validate_decoding([#Float(-0.6)]);
            assert validate_decoding([#Float(1.1), #Float(-1.1)]);
        }); 

        test("options", func(){
            // assert validate_decoding_with_types([#Null], [#Option(#Option(#Option(#Int)))]);
            // assert validate_decoding_with_types([#Option(#Null)], [#Option(#Option(#Option(#Int)))]);
            // assert validate_decoding_with_types([#Option(#Option(#Null))], [#Option(#Option(#Option(#Int)))]);
            assert validate_decoding_with_types([#Option(#Option(#Option(#Int(32))))], [#Option(#Option(#Option(#Int)))]);

            assert validate_decoding([#Option(#Int(6)), #Option(#Int(7))]); // does it reference the same type?
            assert validate_decoding([#Option(#Option(#Int(6)))]);
            assert validate_decoding([#Option(#Nat(0)), #Option(#Text("random text")), #Option(#Option(#Option(#Option(#Option(#Option(#Option(#Option(#Text("nested option")))))))))]);

        });

        test(
            "record types",
            func() {
                assert validate_decoding([#Record([])]);
                assert validate_decoding([#Record([("a", #Nat(0))])]);
                assert validate_decoding([#Record([("a", #Nat(0)), ("b", #Int(1)), ("c", #Text("random"))])]);

                assert validate_decoding([#Record([("a", #Option(#Text("random"))), ("b", #Nat(1))])]);
                assert validate_decoding([#Record([("a", #Nat(1)), ("b", #Option(#Text("random")))])]);
                assert validate_decoding([#Option(#Text("random")), #Record([("a", #Nat(1)), ("b", #Option(#Text("random")))])]);
                assert validate_decoding([#Record([("a", #Array([#Nat(0)])), ("b", #Int(1))])]);
                assert validate_decoding([#Record([("a", #Array([#Nat(0)])), ("b", #Option(#Text("random"))), ("c", #Int(1))])]);
                assert validate_decoding([#Array([#Nat(0)]), #Option(#Text("random")), #Record([("a", #Array([#Nat(0)])), ("b", #Option(#Text("random"))), ("c", #Int(1))])]);

                // nested records
                assert validate_decoding([#Record([("a", #Record([("b", #Nat(0))]))])]);
                assert validate_decoding([#Record([("c", #Nat(0))]), #Record([("a", #Record([("b", #Record([("c", #Nat(0))]))]))])]);
                assert validate_decoding([#Record([("a", #Record([("b", #Record([("c", #Record([("d", #Record([("e", #Nat(0))]))]))]))]))])]);

                // assert validate_decoding([
                //     #Option(#Record([("b", #Nat(0))])),
                //     #Record([
                //         ("a", #Option(#Record([("b", #Nat(0))]))),
                //         ("b", #Array([#Option(#Record([("b", #Array([#Option(#Record([("b", #Nat(0))])), #Option(#Record([("b", #Nat(0))]))]))])), #Option(#Null)])),
                //     ]),
                // ]);

                // tuples 
                // assert validate_decoding([#Record([("0", #Nat(0)), ("1", #Nat(1))])]);

            },
        );

        
    },
);

suite(
    "One Shot decoding - skip types section by adding types",
    func(){
        test("primitives", func(){
            assert validate_decoding_with_types([], []);
            assert validate_decoding_with_types([#Nat(0)], [#Nat]);
            assert validate_decoding_with_types([#Nat(1)], [#Nat]);
            assert validate_decoding_with_types([#Nat(9_223_372_036_854_775_807)], [#Nat]);
            assert validate_decoding_with_types([#Nat(18_446_744_073_709_551_615)], [#Nat]); // limited to Nat64 for now
            assert validate_decoding_with_types([#Nat(0), #Nat(1), #Nat(18_446_744_073_709_551_615)], [#Nat, #Nat, #Nat]);

            assert validate_decoding_with_types([#Nat8(0)], [#Nat8]);
            assert validate_decoding_with_types([#Nat8(1)], [#Nat8]);
            assert validate_decoding_with_types([#Nat8(255)], [#Nat8]);
            assert validate_decoding_with_types([#Nat8(0), #Nat8(1), #Nat8(255)], [#Nat8, #Nat8, #Nat8]);

            assert validate_decoding_with_types([#Nat16(0)], [#Nat16]);
            assert validate_decoding_with_types([#Nat16(1)], [#Nat16]);
            assert validate_decoding_with_types([#Nat16(65_535)], [#Nat16]);
            assert validate_decoding_with_types([#Nat16(0), #Nat16(1), #Nat16(65_535)], [#Nat16, #Nat16, #Nat16]);

            assert validate_decoding_with_types([#Nat32(0)], [#Nat32]);
            assert validate_decoding_with_types([#Nat32(1)], [#Nat32]);
            assert validate_decoding_with_types([#Nat32(4_294_967_295)], [#Nat32]);
            assert validate_decoding_with_types([#Nat32(0), #Nat32(1), #Nat32(4_294_967_295)], [#Nat32, #Nat32, #Nat32]);

            assert validate_decoding_with_types([#Nat64(0)], [#Nat64]);
            assert validate_decoding_with_types([#Nat64(1)], [#Nat64]);
            assert validate_decoding_with_types([#Nat64(18_446_744_073_709_551_615)], [#Nat64]);
            assert validate_decoding_with_types([#Nat64(0), #Nat64(1), #Nat64(18_446_744_073_709_551_615)], [#Nat64, #Nat64, #Nat64]);

            assert validate_decoding_with_types([#Int(1)], [#Int]);
            assert validate_decoding_with_types([#Int(-1)], [#Int]);
            assert validate_decoding_with_types([#Int(127)], [#Int]);
            assert validate_decoding_with_types([#Int(-127)], [#Int]);
            assert validate_decoding_with_types([#Int(123_456_789)], [#Int]);
            assert validate_decoding_with_types([#Int(-123_456_789)], [#Int]);
            assert validate_decoding_with_types([#Int(2_147_483_647)], [#Int]);
            assert validate_decoding_with_types([#Int(-2_147_483_648)], [#Int]);

            assert validate_decoding_with_types([#Int8(1)], [#Int8]);
            assert validate_decoding_with_types([#Int8(-1)], [#Int8]);
            assert validate_decoding_with_types([#Int8(127)], [#Int8]);
            assert validate_decoding_with_types([#Int8(-128)], [#Int8]);

            assert validate_decoding_with_types([#Int16(1)], [#Int16]);
            assert validate_decoding_with_types([#Int16(-1)], [#Int16]);
            assert validate_decoding_with_types([#Int16(32_767)], [#Int16]);
            assert validate_decoding_with_types([#Int16(-32_768)], [#Int16]);

            assert validate_decoding_with_types([#Int32(1)], [#Int32]);
            assert validate_decoding_with_types([#Int32(-1)], [#Int32]);
            assert validate_decoding_with_types([#Int32(2_147_483_647)], [#Int32]);
            assert validate_decoding_with_types([#Int32(-2_147_483_648)], [#Int32]);

            assert validate_decoding_with_types([#Int64(1)], [#Int64]);
            assert validate_decoding_with_types([#Int64(-1)], [#Int64]);
            assert validate_decoding_with_types([#Int64(9_223_372_036_854_775_807)], [#Int64]);
            assert validate_decoding_with_types([#Int64(-9_223_372_036_854_775_808)], [#Int64]);

            assert validate_decoding_with_types([#Bool(true)], [#Bool]);
            assert validate_decoding_with_types([#Bool(false)], [#Bool]);

            assert validate_decoding_with_types([#Null], [#Null]);
            assert validate_decoding_with_types([#Empty], [#Empty]);
            assert validate_decoding_with_types([#Text("")], [#Text]);
            assert validate_decoding_with_types([#Text("random text")], [#Text]);

            assert validate_decoding_with_types([#Principal(Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"))], [#Principal]);

            assert validate_decoding_with_types([#Float(0.0)], [#Float]);
            assert validate_decoding_with_types([#Float(0.6)], [#Float]);
            assert validate_decoding_with_types([#Float(-0.6)], [#Float]);
            assert validate_decoding_with_types([#Float(1.1), #Float(-1.1)], [#Float, #Float]);

            assert validate_decoding_with_types([#Nat(0), #Int(1), #Text("random text")], [#Nat, #Int, #Text]);
        }); 

        test(
            "record types",
            func() {
                assert validate_decoding_with_types([#Record([])], [#Record([])]);
                assert validate_decoding_with_types([#Record([("a", #Nat(0))])], [#Record([("a", #Nat)])]);
                assert validate_decoding_with_types([#Record([("a", #Nat(0)), ("b", #Int(1)), ("c", #Text("random"))])], [#Record([("a", #Nat), ("b", #Int), ("c", #Text)])]);

                assert validate_decoding_with_types([#Record([("a", #Option(#Text("random"))), ("b", #Nat(1))])], [#Record([("a", #Option(#Text)), ("b", #Nat)])]);
                assert validate_decoding_with_types([#Record([("a", #Nat(1)), ("b", #Option(#Text("random")))])], [#Record([("a", #Nat), ("b", #Option(#Text))])]);
                assert validate_decoding_with_types([#Option(#Text("random")), #Record([("a", #Nat(1)), ("b", #Option(#Text("random")))])], [#Option(#Text), #Record([("a", #Nat), ("b", #Option(#Text))])]);
                assert validate_decoding_with_types([#Record([("a", #Array([#Nat(0)])), ("b", #Int(1))])], [#Record([("a", #Array(#Nat)), ("b", #Int)])]);
                assert validate_decoding_with_types([#Record([("a", #Array([#Nat(0)])), ("b", #Option(#Text("random"))), ("c", #Int(1))])], [#Record([("a", #Array(#Nat)), ("b", #Option(#Text)), ("c", #Int)])]);
                assert validate_decoding_with_types([#Array([#Nat(0)]), #Option(#Text("random")), #Record([("a", #Array([#Nat(0)])), ("b", #Option(#Text("random"))), ("c", #Int(1))])], [#Array(#Nat), #Option(#Text), #Record([("a", #Array(#Nat)), ("b", #Option(#Text)), ("c", #Int)])]);

                // nested records
                assert validate_decoding_with_types([#Record([("a", #Record([("b", #Nat(0))]))])], [#Record([("a", #Record([("b", #Nat)]))])]);
                assert validate_decoding_with_types([#Record([("c", #Nat(0))]), #Record([("a", #Record([("b", #Record([("c", #Nat(0))]))]))])], [#Record([("c", #Nat)]), #Record([("a", #Record([("b", #Record([("c", #Nat)]))]))])]);
                assert validate_decoding_with_types([#Record([("a", #Record([("b", #Record([("c", #Record([("d", #Record([("e", #Nat(0))]))]))]))]))])], [#Record([("a", #Record([("b", #Record([("c", #Record([("d", #Record([("e", #Nat)]))]))]))]))])]);

                // assert validate_decoding_with_types([
                //     #Option(#Record([("b", #Nat(0))])),
                //     #Record([
                //         ("a", #Option(#Record([("b", #Nat(0))]))),
                //         ("b", #Array([#Option(#Record([("b", #Array([#Option(#Record([("b", #Nat(0))])), #Option(#Record([("b", #Nat(0))]))]))])), #Option(#Null)])),
                //     ]),
                // ],
                // [
                //     #Option(#Record([("b", #Nat)])),
                //     #Record([
                //         ("a", #Option(#Record([("b", #Nat)]))),
                //         ("b", #Array([#Option(#Record([("b", #Array([#Option(#Record([("b", #Nat)])), #Option(#Record([("b", #Nat)]))]))])), #Option(#Null)])),
                //     ]),
                // ]
                // );

                // tuples 
                // assert validate_decoding_with_types([#Record([("0", #Nat(0)), ("1", #Nat(1))])]);

            },
        );
    }
);