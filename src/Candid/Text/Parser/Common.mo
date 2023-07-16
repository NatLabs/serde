import Char "mo:base/Char";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";
import NatX "mo:xtended-numbers/NatX";

import Candid "../../Types";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    // Parsers

    public func ignoreSpace<A>(parser : P.Parser<Char, A>) : P.Parser<Char, A> {
        C.right(
            C.many(C.Character.space()),
            parser,
        );
    };

    public func removeUnderscore<A>(parser : P.Parser<Char, A>) : P.Parser<Char, List<A>> {
        C.map(
            ignoreSpace(
                C.sepBy1<Char, List<A>, Char>(
                    C.many1(parser),
                    C.Character.char('_'),
                ),
            ),
            func(nested_lists : List<List<A>>) : List<A> {
                List.flatten(nested_lists);
            },
        );
    };

    public func any<T>() : Parser<T, T> {
        C.sat<T>(
            func(c : T) : Bool { true },
        );
    };

    public func hexChar() : Parser<Char, Char> {
        C.sat(
            func(x : Char) : Bool {
                '0' <= x and x <= '9' or 'a' <= x and x <= 'f' or 'A' <= x and x <= 'F';
            },
        );
    };

    public func consIf<T, A>(
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

    // Utilities

    public func fromHex(char : Char) : Nat8 {
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

    public func toText(chars : List<Char>) : Text {
        let iter = Iter.fromList(chars);
        Text.fromIter(iter);
    };

    public func listToNat(digits : List<Char>) : Nat {
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
};