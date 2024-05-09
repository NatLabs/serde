import List "mo:base/List";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

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
                        P.delay(candidParser),
                    ),
                ),
            ),
            func(candid : Candid) : Candid {
                #Option(candid)
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
