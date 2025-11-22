import Float "mo:base@0.16.0/Float";
import List "mo:base@0.16.0/List";

import C "../../../../submodules/parser-combinators.mo/src/Combinators";
import P "../../../../submodules/parser-combinators.mo/src/Parser";

import Candid "../../Types";

import { listToNat } "Common";
import { parseInt } "Int";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func floatParser() : Parser<Char, Candid> {

        func toFloat(tuple : (Int, List<Char>)) : Candid {
            let (n, d_chars) = tuple;

            let n_of_decimals = Float.fromInt(List.size(d_chars));

            let num = Float.fromInt(n);
            let decimals = Float.fromInt(listToNat(d_chars)) / (10 ** n_of_decimals);

            let isNegative = num < 0;

            let float = if (isNegative) {
                num - decimals;
            } else {
                num + decimals;
            };

            #Float(float);
        };

        C.map(
            parseFloat(),
            toFloat,
        );
    };

    func parseFloat() : Parser<Char, (Int, List<Char>)> {
        C.seq<Char, Int, List<Char>>(
            parseInt(),
            C.right(
                C.Character.char('.'),
                C.many1(C.Character.digit()),
            ),
        );
    };
};
