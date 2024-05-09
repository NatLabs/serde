import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat64 "mo:base/Nat64";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";
import NatX "mo:xtended-numbers/NatX";

import Candid "../../Types";
import { ignoreSpace; hexChar; fromHex; removeUnderscore; listToNat } "Common";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func natParser() : Parser<Char, Candid> {
        C.map(
            parseNat(),
            func(n : Nat) : Candid {
                #Nat(n);
            },
        );
    };

    public func parseNat() : Parser<Char, Nat> {
        C.oneOf([
            parseNatFromHex(),
            parseNatWithUnderscore(),
            C.Nat.nat(),
        ]);
    };

    func parseNatWithUnderscore() : Parser<Char, Nat> {
        C.map(
            ignoreSpace(
                removeUnderscore(C.Character.digit()),
            ),
            listToNat,
        );
    };

    func parseNatFromHex() : Parser<Char, Nat> {
        C.map(
            C.right(
                C.String.string("0x"),
                removeUnderscore(hexChar()),
            ),
            func(chars : List<Char>) : Nat {
                var n : Nat64 = 0;

                for (hex in Iter.fromList(chars)) {
                    n := (n << 4) + NatX.from8To64(fromHex(hex));
                };

                // debug { Debug.print("hex_chars: " # debug_show (chars, n)) };

                Nat64.toNat(n);
            },
        );
    };

};
