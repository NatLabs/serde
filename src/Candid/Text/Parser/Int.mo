import Int "mo:base/Int";
import List "mo:base/List";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../../Types";

import { parseNat } "Nat";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func intParser() : Parser<Char, Candid> {
        C.map(
            wrapNatToIntParser(parseNat()),
            func(n : Int) : Candid {
                if (n < 0) {
                    #Int(n);
                } else {
                    #Nat(Int.abs(n));
                };
            },
        );
    };

    public func parseInt() : Parser<Char, Int> {
        wrapNatToIntParser(parseNat());
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
};
