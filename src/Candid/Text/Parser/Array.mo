import List "mo:base@0.16.0/List";

import C "../../../../submodules/parser-combinators.mo/src/Combinators";
import P "../../../../submodules/parser-combinators.mo/src/Parser";

import Candid "../../Types";

import { ignoreSpace } "Common";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func arrayParser(valueParser : () -> Parser<Char, Candid>) : Parser<Char, Candid> {
        C.map(
            C.right(
                ignoreSpace(
                    C.String.string("vec")
                ),
                ignoreSpace(
                    C.bracket(
                        C.String.string("{"),
                        ignoreSpace(
                            C.sepBy(
                                P.delay(valueParser),
                                ignoreSpace(C.Character.char(';')),
                            )
                        ),
                        C.oneOf([
                            C.right(
                                ignoreSpace(C.Character.char(';')),
                                ignoreSpace(C.String.string("}")),
                            ),
                            ignoreSpace(C.String.string("}")),
                        ]),
                    )
                ),
            ),
            func(list : List<Candid>) : Candid {
                #Array(List.toArray(list));
            },
        );
    };
};
