import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat32 "mo:base/Nat32";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";
import Itertools "mo:itertools/Iter";

import Candid "../Candid";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;
    type Parser<T, A> = P.Parser<T, A>;

    public func parseValue(text : Text) : Candid {
        let t = switch (text) {
            case ("true") return #Bool(true);
            case ("false") return #Bool(false);
            case ("null") return #Null;
            case ("") return #Empty;
            case (t) t;
        };

        let list = Iter.toList(t.chars());

        // todo: parse Float, Principal
        switch (parseCharList(list)) {
            case (?candid) candid;
            case (null) #Text(text);
        };
    };

    func parseCharList(l : List.List<Char>) : ?Candid {
        switch (valueParser()(l)) {
            case (null) { null };
            case (?(x, xs)) {
                switch (xs) {
                    case (null) { ?x };
                    case (_) { null };
                };
            };
        };
    };

    func valueParser() : Parser<Char, Candid> {
        C.oneOf([
            natParser(),
            intParser(),
        ]);
    };

    func intParser() : Parser<Char, Candid> {
        func(xs : List<Char>) : ?(Candid, List<Char>) {
            let (op, ys) = switch (C.Character.char('-')(xs)) {
                case (null) { (func(n : Nat) : Candid { #Nat(n) }, xs) };
                case (?(_, xs)) { (func(n : Nat) : Candid { #Int(-n) }, xs) };
            };

            let mapToNat = C.map(
                C.many1(C.Character.digit()),
                listToNat,
            );

            let mapToCandid = C.map<Char, Nat, Candid>(
                mapToNat,
                op,
            );

            mapToCandid(ys);
        };
    };

    func natParser() : Parser<Char, Candid> {

        let toNat = C.map(
            consIf<Char, Char>(
                C.Character.digit(),
                C.many(C.Character.digit()),

                // fail if number has leading zeros
                func(digit : Char, digits : List<Char>) : Bool {
                    digits != ?('0', null);
                },
            ),
            listToNat,
        );

        C.map(
            toNat,
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
