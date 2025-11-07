import List "mo:base@0.16.0/List";

import C "../../../../submodules/parser-combinators.mo/src/Combinators";
import P "../../../../submodules/parser-combinators.mo/src/Parser";

import Candid "../../Types";
import { ignoreSpace } "Common";

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
                ])
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
