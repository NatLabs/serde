import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import List "mo:base/List";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../../Types";
import { ignoreSpace; hexChar; fromHex } "Common";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func blobParser() : Parser<Char, Candid> {
        C.map(
            C.right(
                C.String.string("blob"),
                ignoreSpace(
                    C.bracket(
                        C.String.string("\""),
                        C.sepBy(
                            C.map(
                                C.right(
                                    C.String.string("\\"),
                                    C.seq(
                                        hexChar(),
                                        hexChar(),
                                    ),
                                ),
                                func((c1, c2) : (Char, Char)) : Nat8 {
                                    (fromHex(c1) << 4) + fromHex(c2);
                                },
                            ),
                            C.String.string(""), // escapes char: '\'
                        ),
                        C.String.string("\""),
                    ),
                ),
            ),
            func(chars : List<Nat8>) : Candid {
                let blob = Blob.fromArray(Iter.toArray(Iter.fromList(chars)));
                #Blob(blob);
            },
        );
    };
};
