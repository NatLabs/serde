import Char "mo:base/Char";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Text "mo:base/Text";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../../Types";

module{
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func textParser() : Parser<Char, Candid> {
        C.map(
            parseText(),
            func(text : Text) : Candid {
                #Text(text);
            },
        );
    };

    public func parseText(): Parser<Char, Text>{
        C.map(
            C.bracket(
                C.String.string("\""),
                C.many(textChar()),
                C.String.string("\""),
            ),
            func(chars : List<Char>) : Text {
                Text.fromIter(Iter.fromList(chars));
            },
        );
    };

    func textChar() : P.Parser<Char, Char> = C.oneOf([
        C.sat<Char>(func (c : Char) : Bool {
            c != Char.fromNat32(0x22) and c != '\\';
        }),
        C.right(
            C.Character.char('\\'),
            C.map(
                C.Character.oneOf([
                    Char.fromNat32(0x22), '\\', '/', 'b', 'f', 'n', 'r', 't',
                    // TODO: u hex{4}
                ]),
                func (c : Char) : Char {
                    switch (c) {
                        case ('b') { Char.fromNat32(0x08); };
                        case ('f') { Char.fromNat32(0x0C); };
                        case ('n') { Char.fromNat32(0x0A); };
                        case ('r') { Char.fromNat32(0x0D); };
                        case ('t') { Char.fromNat32(0x09); };
                        case (_) { c; };
                    };
                }
            )
        )
    ]);
}