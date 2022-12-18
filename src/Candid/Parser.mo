import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Float "mo:base/Float";
import List "mo:base/List";
import Nat32 "mo:base/Nat32";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";
import Itertools "mo:itertools/Iter";

import Candid "../Candid";
import U "../Utils";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func parse(text : Text) : Candid {
        let t = switch (text) {
            case ("true") return #Bool(true);
            case ("false") return #Bool(false);
            case ("null") return #Null;
            case ("") return #Empty;
            case (t) t;
        };

        let chars = Iter.toList(t.chars());

        // todo: parse Principal
        switch (parseCandid(chars)) {
            case (?candid) candid;
            case (null) #Text(text);
        };
    };

    func ignoreSpace<A>(parserA : P.Parser<Char, A>) : P.Parser<Char, A> {
        C.right(
            C.many(C.Character.space()),
            parserA,
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
                    case (_) {
                        null;
                    };
                };
            };
        };
    };

    func candidParser() : Parser<Char, Candid> {
        C.oneOf([]);
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
        func(xs : List<Char>) : ?(Int, List<Char>) {
            let (op, ys) = switch (C.Character.char('-')(xs)) {
                case (null) { (func(n : Nat) : Int { n }, xs) };
                case (?(_, xs)) { (func(n : Nat) : Int { -n }, xs) };
            };

            let mapToInt = C.map<Char, Nat, Int>(
                parseNat(),
                op,
            );

            mapToInt(ys);
        };
    };

    func intParser() : Parser<Char, Candid> {
        C.map(
            parseInt(),
            func(n : Int) : Candid {
                #Int(n);
            },
        );
    };

    func parseNat() : Parser<Char, Nat> {
        let noLeadingZeroes = consIf<Char, Char>(
            C.Character.digit(),
            C.many(C.Character.digit()),

            func(first_digit : Char, digits : List<Char>) : Bool {
                let size_eq_1 = switch (List.pop(digits)) {
                    case ((_, xs)) xs == null;
                };

                first_digit != '0' or size_eq_1;
            },
        );

        C.map(
            noLeadingZeroes,
            listToNat,
        );
    };

    func natParser() : Parser<Char, Candid> {
        C.map(
            parseNat(),
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

};
