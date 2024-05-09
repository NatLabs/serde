import List "mo:base/List";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../../Types";
import { ignoreSpace; } "Common";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func boolParser() : Parser<Char, Candid> {
        C.map(parseBool(), func(b : Bool) : Candid { #Bool(b) });
    };

    func parseBool() : Parser<Char, Bool> {
        C.map(
            ignoreSpace(
                C.oneOf([
                    C.String.string("true"),
                    C.String.string("false"),
                ]),
            ),
            func(t : Text) : Bool {
                switch (t) {
                    case ("true") true;
                    case (_) false;
                };
            },
        );
    };
};
