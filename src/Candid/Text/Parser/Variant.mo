import List "mo:base/List";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../../Types";
import { ignoreSpace } "Common";
import { keyParser; fieldParser } = "Record";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func variantParser(candidParser : () -> Parser<Char, Candid>) : Parser<Char, Candid> {
        let emptyValueParser = C.map<Char, Text, (Text, Candid)>(
            keyParser(),
            func(key : Text) : (Text, Candid) {
                (key, #Null);
            },
        );

        C.map(
            C.right(
                C.String.string("variant"),
                ignoreSpace(
                    C.bracket(
                        C.String.string("{"),
                        ignoreSpace(
                            C.oneOf([
                                fieldParser(candidParser),
                                emptyValueParser,
                            ]),
                        ),
                        ignoreSpace(C.String.string("}")),
                    ),
                ),
            ),
            func(variant : (Text, Candid)) : Candid {
                #Variant(variant);
            },
        );
    };
};
