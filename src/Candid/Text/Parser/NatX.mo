import Debug "mo:base@0.16.0/Debug";
import List "mo:base@0.16.0/List";
import Nat8 "mo:base@0.16.0/Nat8";
import Nat16 "mo:base@0.16.0/Nat16";
import Nat32 "mo:base@0.16.0/Nat32";
import Nat64 "mo:base@0.16.0/Nat64";

import C "../../../../submodules/parser-combinators.mo/src/Combinators";
import P "../../../../submodules/parser-combinators.mo/src/Parser";

import Candid "../../Types";
import { ignoreSpace } "Common";
import { parseNat } "Nat";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func natXParser() : Parser<Char, Candid> {
        C.map(
            parseNatX(),
            func((nat, natType) : (Nat, Text)) : Candid {
                switch (natType) {
                    case ("nat") #Nat(nat);
                    case ("nat8") #Nat8(Nat8.fromNat(nat));
                    case ("nat16") #Nat16(Nat16.fromNat(nat));
                    case ("nat32") #Nat32(Nat32.fromNat(nat));
                    case ("nat64") #Nat64(Nat64.fromNat(nat));
                    case (_) Debug.trap("Only nat8, nat16, nat32, nat64 nat bit types but got '" # natType # "'");
                };
            },
        );
    };

    func parseNatX() : Parser<Char, (Nat, Text)> {
        ignoreSpace(
            C.seq(
                parseNat(),
                ignoreSpace(
                    C.right(
                        C.Character.char(':'),
                        ignoreSpace(
                            C.oneOf([
                                C.String.string("nat64"),
                                C.String.string("nat32"),
                                C.String.string("nat16"),
                                C.String.string("nat8"),
                                C.String.string("nat"),
                            ])
                        ),
                    )
                ),
            )
        );
    };
};
