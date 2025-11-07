import List "mo:base@0.16.0/List";
import Principal "mo:base@0.16.0/Principal";

import C "../../../../submodules/parser-combinators.mo/src/Combinators";
import P "../../../../submodules/parser-combinators.mo/src/Parser";

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
                            ])
                        ),
                        C.String.string("\""),
                    )
                ),
            ),
            func(chars : List<Char>) : Candid {
                let text = toText(chars);
                #Principal(Principal.fromText(text));
            },
        );
    };
};
