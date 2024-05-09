import List "mo:base/List";
import Principal "mo:base/Principal";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../../Types";
import { ignoreSpace; toText } "Common";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func principalParser() : Parser<Char, Candid> {
        C.map(
            C.right(
                C.String.string("principal"),
                ignoreSpace(
                    C.bracket(
                        C.String.string("\""),
                        C.many1(
                            C.oneOf([
                                C.Character.alphanum(),
                                C.Character.char('-'),
                            ]),
                        ),
                        C.String.string("\""),
                    ),
                ),
            ),
            func(chars : List<Char>) : Candid {
                let text = toText(chars);
                #Principal(Principal.fromText(text));
            },
        );
    };
};
