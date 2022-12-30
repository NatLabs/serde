import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import List "mo:base/List";
import Nat32 "mo:base/Nat32";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";
import Itertools "mo:itertools/Iter";
import NatX "mo:xtended-numbers/NatX";

import Candid "../Candid/Types";
import U "../Utils";

module CandidParser {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func parse(text : Text) : Candid {
        let chars = Iter.toList(text.chars());

        switch (parseCandid(chars)) {
            case (?candid) candid;
            case (null) Debug.trap("Failed to parse Candid text");
        };
    };

    func ignoreSpace<A>(parserA : P.Parser<Char, A>) : P.Parser<Char, A> {
        C.right(
            C.many(C.Character.space()),
            parserA,
        );
    };

    func ignoreUnderscore(parser : P.Parser<Char, Char>) : P.Parser<Char, List<Char>> {
        let x : Parser<Char, List<Char>> = C.sepBy<Char, Char, Char>(
            C.Character.digit(),
            C.Character.char('_'),
        );

        let y = func(nested_lists : List<List<Char>>) : List<Char> {
            List.flatten(nested_lists);
        };

        C.map(
            x,
            func(xs : List<Char>) : List<Char> {
                Debug.print("ignoreUnderscore: " # debug_show (xs));
                xs;
            },
        );
    };

    // func recordParser() : Parser<Char, Candid> {
    //     C.map(
    //         C.right(
    //             C.String.string("record"),
    //             ignoreSpace(
    //                 C.bracket(
    //                     C.String.string("{"),
    //                     ignoreSpace(
    //                         C.sepBy(
    //                             C.seq(
    //                                 C.map(
    //                                     C.many1(C.Character.alphanum()),
    //                                     C.String.string(),
    //                                 ),
    //                                 ignoreSpace(
    //                                     C.right(
    //                                         C.Character.char('='),
    //                                         ignoreSpace(
    //                                             candidParser(),
    //                                         ),
    //                                     ),
    //                                 ),
    //                             ),
    //                             C.Character.char(';'),
    //                         ),
    //                     ),
    //                     C.String.string("}"),
    //                 ),
    //             ),
    //         ),

    //         func(xs : List<(Text, Candid)>) : Candid {
    //             let records = Iter.toArray(Iter.fromList(xs));
    //             #Record(records);
    //         },
    //     )
    // };

    func parseCandid(l : List.List<Char>) : ?Candid {
        switch (candidParser()(l)) {
            case (null) { null };
            case (?(x, xs)) {
                switch (xs) {
                    case (null) { ?x };
                    case (_xs) {
                        Debug.print("Failed parseCandid: " # debug_show (x, _xs));
                        null;
                    };
                };
            };
        };
    };

    func candidParser() : Parser<Char, Candid> {
        let supportedParsers = [
            principalParser(),
            blobParser(),
            natParser(),
            intParser(),
            floatParser(),
            textParser(),
            // boolParser(),
            // nullParser(),
            // emptyParser(),
            // recordParser(),
        ];

        C.oneOf([
            C.bracket(
                C.String.string("("),
                ignoreSpace(
                    C.oneOf(supportedParsers),
                ),
                C.String.string(")"),
            ),
            C.bracket(
                C.many(C.Character.space()),
                C.oneOf(supportedParsers),
                C.many(C.Character.space()),
            ),
        ]);
    };

    func textParser() : Parser<Char, Candid> {
        C.map(
            C.bracket(
                C.String.string("\""),
                C.many1(any<Char>()),
                C.String.string("\""),
            ),
            func(chars : List<Char>) : Candid {
                let text = Itertools.toText(Iter.fromList(chars));
                #Text(text);
            },
        );
    };

    func blobParser() : Parser<Char, Candid> {
        C.map(
            C.right(
                C.String.string("blob"),
                ignoreSpace(
                    C.bracket(
                        C.String.string("\""),
                        C.right(
                            C.Character.char('\\'), // skips the first '\'
                            C.sepBy(
                                C.map(
                                    C.seq(
                                        C.Character.hex(),
                                        C.Character.hex(),
                                    ),
                                    func((c1, c2) : (Char, Char)) : Nat8 {
                                        (fromHex(c1) << 4) + fromHex(c2);
                                    },
                                ),
                                C.Character.char('\\'), // escapes char: '\'
                            ),
                        ),
                        C.String.string("\""),
                    ),
                ),
            ),
            func(chars : List<Nat8>) : Candid {
                let blob = Blob.fromArray(Iter.toArray(Iter.fromList(chars)));
                #Blob(blob);
            },
        );
    };

    // func stringLengthParser() : Parser<Char, Int> {

    // };

    func principalParser() : Parser<Char, Candid> {
        C.map(
            C.right(
                C.String.string("principal"),
                ignoreSpace(
                    C.bracket(
                        C.String.string("\""),
                        C.many1(
                            C.oneOf([
                                C.Character.alphanum(),
                                C.Character.char('-'),
                            ]),
                        ),
                        C.String.string("\""),
                    ),
                ),
            ),
            func(chars : List<Char>) : Candid {
                let text = toText(chars);
                #Principal(Principal.fromText(text));
            },
        );
    };

    func toText(chars : List<Char>) : Text {
        let iter = Iter.fromList(chars);
        Itertools.toText(iter);
    };

    func floatParser() : Parser<Char, Candid> {

        func toFloat(tuple : (Int, List<Char>)) : Candid {
            let (n, d_chars) = tuple;

            let n_of_decimals = Float.fromInt(List.size(d_chars));

            let num = Float.fromInt(n);
            let decimals = Float.fromInt(listToNat(d_chars)) / (10 ** n_of_decimals);

            let isNegative = num < 0;

            let float = if (isNegative) {
                num - decimals;
            } else {
                num + decimals;
            };

            #Float(float);
        };

        C.map(
            parseFloat(),
            toFloat,
        );
    };

    func parseFloat() : Parser<Char, (Int, List<Char>)> {
        C.seq<Char, Int, List<Char>>(
            parseInt(),
            C.right(
                C.Character.char('.'),
                C.many1(C.Character.digit()),
            ),
        );
    };

    func parseInt() : Parser<Char, Int> {
        wrapNatToIntParser(C.Nat.nat());
    };

    func wrapNatToIntParser(natParser : Parser<Char, Nat>) : Parser<Char, Int> {
        func(xs : List<Char>) : ?(Int, List<Char>) {

            let parseSign = C.oneOf([
                C.Character.char('+'),
                C.Character.char('-'),
            ]);

            let (toInt, ys) = switch (parseSign(xs)) {
                case (null) { (func(n : Nat) : Int { n }, xs) };
                case (?('+', xs)) { (func(n : Nat) : Int { n }, xs) };
                case (?(_, xs)) { (func(n : Nat) : Int { -n }, xs) };
            };

            let mapToInt = C.map<Char, Nat, Int>(
                natParser,
                toInt,
            );

            mapToInt(ys);
        };
    };

    func parseIntWithUnderscore() : Parser<Char, Int> {
        wrapNatToIntParser(parseNatWithUnderscore());
    };

    func intParser() : Parser<Char, Candid> {
        C.map(
            C.oneOf([
                parseIntWithUnderscore(),
                parseInt(),
            ]),
            func(n : Int) : Candid {
                if (n < 0) {
                    #Int(n);
                } else {
                    #Nat(Int.abs(n));
                };
            },
        );
    };

    func parseNatWithUnderscore() : Parser<Char, Nat> {
        C.map(
            ignoreSpace(
                C.sepBy1<Char, List<Char>, Char>(
                    C.many1(C.Character.digit()),
                    C.Character.char('_'),
                ),
            ),
            func(nested_lists : List<List<Char>>) : Nat {
                let flattened = List.flatten(nested_lists);

                debug {
                    Debug.print("nested_lists: " # debug_show (nested_lists));
                    Debug.print("flattened: " # debug_show (flattened));
                };

                listToNat(flattened);
            },
        );
    };

    // func parseNatFromHex(): Parser<Char, Nat>{
    //     C.right(
    //         C.Character.char('0'),
    //         C.right(
    //             C.Character.char('x'),

    //         )
    //     )
    // };

    func natParser() : Parser<Char, Candid> {
        C.map(
            C.oneOf<Char, Nat>([
                parseNatWithUnderscore(),
                C.Nat.nat(),
                // C.map(
                //     ignoreUnderscore(C.Character.digit()),
                //     listToNat
                // ),
            ]),

            func(n : Nat) : Candid {
                #Nat(n);
            },
        );
    };

    func listToNat(digits : List<Char>) : Nat {
        List.foldLeft<Char, Nat>(
            digits,
            0,
            func(n : Nat, c : Char) : Nat {
                let digit = Nat32.toNat(
                    Char.toNat32(c) - Char.toNat32('0'),
                );

                (10 * n) + digit;
            },
        );
    };

    func consIf<T, A>(
        parserA : Parser<T, A>,
        parserAs : Parser<T, List<A>>,
        cond : (A, List<A>) -> Bool,
    ) : Parser<T, List<A>> {
        C.bind(
            parserA,
            func(a : A) : Parser<T, List<A>> {
                C.bind(
                    parserAs,
                    func(as : List<A>) : Parser<T, List<A>> {
                        if (cond(a, as)) {
                            P.result<T, List<A>>(List.push(a, as));
                        } else {
                            P.zero();
                        };
                    },
                );
            },
        );
    };

    func fromHex(char : Char) : Nat8 {
        let charCode = Char.toNat32(char);

        if (Char.isDigit(char)) {
            let digit = charCode - Char.toNat32('0');

            return NatX.from32To8(digit);
        };

        if (Char.isUppercase(char)) {
            let digit = charCode - Char.toNat32('A') + 10;

            return NatX.from32To8(digit);
        };

        // lowercase
        let digit = charCode - Char.toNat32('a') + 10;

        return NatX.from32To8(digit);

    };

    func any<T>() : Parser<T, T> {
        C.sat<T>(
            func(c : T) : Bool { true },
        );
    };

};
