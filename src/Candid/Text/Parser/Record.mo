import Iter "mo:base/Iter";
import List "mo:base/List";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../../Types";
import { ignoreSpace; toText } "Common";
import { parseText } "Text";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func recordParser(candidParser : () -> Parser<Char, Candid>) : Parser<Char, Candid> {
        C.map(
            C.right(
                C.String.string("record"),
                ignoreSpace(
                    C.bracket(
                        C.String.string("{"),
                        C.sepBy(
                            fieldParser(candidParser),
                            ignoreSpace(C.Character.char(';')),
                        ),
                        C.oneOf([
                            C.right(
                                ignoreSpace(C.Character.char(';')),
                                ignoreSpace(C.String.string("}")),
                            ),
                            ignoreSpace(C.String.string("}")),
                        ])
                    ),
                ),
            ),
            func(xs : List<(Text, Candid)>) : Candid {
                let records = Iter.toArray(Iter.fromList(xs));
                #Record(records);
            },
        );
    };

    public func fieldParser<Candid>(valueParser: () -> Parser<Char, Candid>): Parser<Char, (Text, Candid)>{
        C.seq(
            ignoreSpace(
                C.left(
                    keyParser(),
                    ignoreSpace(C.Character.char('=')),
                ),
            ),
            ignoreSpace(P.delay(valueParser)),
        );

    };

    public func keyParser(): Parser<Char, Text>{
        C.oneOf([
            C.map(
                C.many1(
                    C.choose(
                        C.Character.alphanum(),
                        C.Character.char('_'),
                    ),
                ),
                toText,
            ),
            parseText()
        ]);
    };
};
