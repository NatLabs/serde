import Char "mo:base@0.16/Char";
import Iter "mo:base@0.16/Iter";
import Int "mo:base@0.16/Int";
import Float "mo:base@0.16/Float";
import List "mo:base@0.16/List";
import Nat8 "mo:base@0.16/Nat8";
import Nat32 "mo:base@0.16/Nat32";
import Result "mo:base@0.16/Result";
import Text "mo:base@0.16/Text";

import C "../../parser-combinators.mo/src/Combinators";
import L "../../parser-combinators.mo/src/List";
import P "../../parser-combinators.mo/src/Parser";

module JSON {
    public type JSON = {
        #Number : Int;
        #Float : Float;
        #String : Text;
        #Array : [JSON];
        #Object : [(Text, JSON)];
        #Boolean : Bool;
        #Null;
    };

    public func show(json : JSON) : Text = switch (json) {
        case (#Number(v)) { Int.toText(v) };
        case (#Float(v)) { Float.format(#fix(2), v) };
        case (#String(v)) { "\"" # v # "\"" };
        case (#Array(v)) {
            var s = "[";
            for (i in v.vals()) {
                if (s != "[") { s #= ", " };
                s #= show(i);
            };
            s # "]";
        };
        case (#Object(v)) {
            var s = "{";
            for ((k, v) in v.vals()) {
                if (s != "{") { s #= ", " };
                s #= "\"" # k # "\"" # ": " # show(v);
            };
            s # "}";
        };
        case (#Boolean(v)) {
            if (v) { return "true" };
            "false";
        };
        case (#Null) { "null" };
    };

    // Parse exactly four hex digits and combine into a Nat32 (one BMP codepoint
    // or one half of a UTF-16 surrogate pair).
    private func fourHexAsNat32() : P.Parser<Char, Nat32> = C.map(
        C.count<Char, Char>(C.Character.hex(), 4),
        func(digits : List.List<Char>) : Nat32 {
            var n : Nat32 = 0;
            for (d in L.toIter(digits)) {
                let v : Nat32 = if (d >= '0' and d <= '9') {
                    Char.toNat32(d) - Char.toNat32('0');
                } else if (d >= 'a' and d <= 'f') {
                    Char.toNat32(d) - Char.toNat32('a') + 10;
                } else {
                    Char.toNat32(d) - Char.toNat32('A') + 10;
                };
                n := n * 16 + v;
            };
            n;
        },
    );

    private func character() : P.Parser<Char, Char> = C.oneOf([
        C.sat<Char>(
            func(c : Char) : Bool {
                c != Char.fromNat32(0x22) and c != '\\';
            }
        ),
        C.right(
            C.Character.char('\\'),
            C.oneOf([
                // \u XXXX  (with surrogate-pair handling for codepoints above BMP).
                // RFC 8259 §7: characters above U+FFFF are encoded as a UTF-16 surrogate pair
                // — high D800..DBFF then low DC00..DFFF, e.g. `🎓` for U+1F393 🎓.
                C.right(
                    C.Character.char('u'),
                    C.bind<Char, Nat32, Char>(
                        fourHexAsNat32(),
                        func(n : Nat32) : P.Parser<Char, Char> {
                            if (n >= 0xD800 and n <= 0xDBFF) {
                                // high surrogate — expect `\u` followed by low surrogate
                                C.bind<Char, Nat32, Char>(
                                    C.right(
                                        C.Character.char('\\'),
                                        C.right(
                                            C.Character.char('u'),
                                            fourHexAsNat32(),
                                        ),
                                    ),
                                    func(low : Nat32) : P.Parser<Char, Char> {
                                        let codepoint : Nat32 = 0x10000 + ((n - 0xD800) * 0x400) + (low - 0xDC00);
                                        P.result<Char, Char>(Char.fromNat32(codepoint));
                                    },
                                );
                            } else {
                                P.result<Char, Char>(Char.fromNat32(n));
                            };
                        },
                    ),
                ),
                // single-char escape (\", \\, \/, \b, \f, \n, \r, \t)
                C.map(
                    C.Character.oneOf([
                        Char.fromNat32(0x22),
                        '\\',
                        '/',
                        'b',
                        'f',
                        'n',
                        'r',
                        't',
                    ]),
                    func(c : Char) : Char {
                        switch (c) {
                            case ('b') { Char.fromNat32(0x08) };
                            case ('f') { Char.fromNat32(0x0C) };
                            case ('n') { Char.fromNat32(0x0A) };
                            case ('r') { Char.fromNat32(0x0D) };
                            case ('t') { Char.fromNat32(0x09) };
                            case (_) { c };
                        };
                    },
                ),
            ]),
        ),
    ]);

    private func ignoreSpace<A>(parserA : P.Parser<Char, A>) : P.Parser<Char, A> = C.right(
        C.many(C.Character.space()),
        parserA,
    );

    public func parse(t : Text) : ?JSON = parseValues(L.fromText(t));

    public func parseRaw(data : [Char]) : ?JSON = parseValues(L.fromIter(data.vals()));

    public func parseRawASCII(data : [Nat8]) : ?JSON = parseValues(nat8sToCharList(data.vals()));

    private func parseValues(l : List.List<Char>) : ?JSON = switch (valueParser()(l)) {
        case (null) { null };
        case (?(x, xs)) {
            switch (xs) {
                case (null) { ?x };
                case (_) { null };
            };
        };
    };

    private func nat8sToCharList(i : Iter.Iter<Nat8>) : List.List<Char> = switch (i.next()) {
        case (null) { null };
        case (?v) {
            ?(Char.fromNat32(Nat32.fromNat(Nat8.toNat(v))), nat8sToCharList(i));
        };
    };

    private func valueParser() : P.Parser<Char, JSON> = C.bracket(
        C.many(C.Character.space()),
        C.oneOf([
            objectParser(),
            arrayParser(),
            stringParser(),
            floatParser(),
            numberParser(),
            boolParser(),
            nullParser(),
        ]),
        C.many(C.Character.space()),
    );

    private func objectParser() : P.Parser<Char, JSON> = C.map(
        C.bracket(
            C.Character.char('{'),
            ignoreSpace(
                C.sepBy(
                    C.seq(
                        C.left(
                            ignoreSpace(string()),
                            ignoreSpace(C.Character.char(':')),
                        ),
                        P.delay(valueParser),
                    ),
                    C.Character.char(','),
                )
            ),
            C.Character.char('}'),
        ),
        func(t : List.List<(Text, JSON)>) : JSON {
            #Object(List.toArray(t));
        },
    );

    private func arrayParser() : P.Parser<Char, JSON> = C.map(
        C.bracket(
            C.Character.char('['),
            ignoreSpace(
                C.sepBy(
                    P.delay(valueParser),
                    C.Character.char(','),
                )
            ),
            C.Character.char(']'),
        ),
        func(t : List.List<JSON>) : JSON {
            #Array(List.toArray(t));
        },
    );

    private func string() : P.Parser<Char, Text> = C.map(
        C.bracket(
            C.Character.char(Char.fromNat32(0x22)),
            C.many(character()),
            C.Character.char(Char.fromNat32(0x22)),
        ),
        func(t : List.List<Char>) : Text {
            Text.fromIter(L.toIter(t));
        },
    );

    private func stringParser() : P.Parser<Char, JSON> = C.map(
        C.map(
            C.bracket(
                C.Character.char(Char.fromNat32(0x22)),
                C.many(character()),
                C.Character.char(Char.fromNat32(0x22)),
            ),
            func(t : List.List<Char>) : Text {
                Text.fromIter(L.toIter(t));
            },
        ),
        func(t : Text) : JSON {
            #String(t);
        },
    );

    private func floatParser() : P.Parser<Char, JSON> = C.map(
        C.oneOf([
            parseFloatWithExp(),
            parseFloat(),
        ]),
        func(n : Float) : JSON = #Float(n),
    );

    private func parseFloat() : P.Parser<Char, Float> {
        C.map(
            C.seq<Char, Int, List.List<Char>>(
                C.Int.int(),
                C.right(
                    C.Character.char('.'),
                    C.many1(C.Character.digit()),
                ),
            ),
            func((n, decimal_list) : (Int, List.List<Char>)) : Float {
                let isNegative = n < 0;
                var num = n;
                var n_of_decimals : Float = 0;

                for (char in List.toIter(decimal_list)) {
                    let digit = Nat32.toNat(
                        Char.toNat32(char) - Char.toNat32('0')
                    );

                    if (isNegative) {
                        num := num * 10 - digit;
                    } else {
                        num := num * 10 + digit;
                    };

                    n_of_decimals += 1;
                };

                let float = Float.fromInt(num) / (10 ** n_of_decimals);
            },
        );
    };

    private func parseFloatWithExp() : P.Parser<Char, Float> = C.map(
        C.seq(
            C.oneOf([
                parseFloat(),
                C.map(
                    C.Int.int(),
                    func(i : Int) : Float = Float.fromInt(i),
                ),
            ]),
            C.right(
                C.oneOf([C.String.string("e"), C.String.string("E")]),
                C.Int.int(),
            ),
        ),
        func((n, exponent) : (Float, Int)) : Float {
            let exp = Float.fromInt(exponent);
            let isNegative = exp < 0;

            if (isNegative) {
                return n / (10 ** -exp);
            };

            n * (10 ** exp);
        },
    );

    private func numberParser() : P.Parser<Char, JSON> = C.map(
        C.Int.int(),
        func(i : Int) : JSON {
            #Number(i);
        },
    );

    private func boolParser() : P.Parser<Char, JSON> = C.map(
        C.choose(
            C.String.string("true"),
            C.String.string("false"),
        ),
        func(t : Text) : JSON {
            if (t == "true") return #Boolean(true);
            #Boolean(false);
        },
    );

    private func nullParser() : P.Parser<Char, JSON> = C.map(
        C.String.string("null"),
        func(_ : Text) : JSON {
            #Null;
        },
    );
};
