import List "mo:base@0.16.0/List";

import C "../../../../submodules/parser-combinators.mo/src/Combinators";
import P "../../../../submodules/parser-combinators.mo/src/Parser";

import Candid "../../Types";

import { ignoreSpace } "Common";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func optionParser(candidParser : () -> Parser<Char, Candid>) : Parser<Char, Candid> {
        C.map(
            ignoreSpace(
                C.right(
                    C.String.string("opt"),
                    ignoreSpace(
                        P.delay(candidParser)
                    ),
                )
            ),
            func(candid : Candid) : Candid {
                #Option(candid);
            },
        );
    };

    public func nullParser() : Parser<Char, Candid> {
        C.map(
            ignoreSpace(C.String.string("null")),
            func(_ : Text) : Candid {
                #Null;
            },
        );
    };
};
