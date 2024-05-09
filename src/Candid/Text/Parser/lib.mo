import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import List "mo:base/List";
import TrieMap "mo:base/TrieMap";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../../Types";

import { ignoreSpace } "Common";

import { arrayParser } "Array";
import { blobParser } "Blob";
import { boolParser } "Bool";
import { floatParser } "Float";
import { intParser } "Int";
import { intXParser } "IntX";
import { natParser } "Nat";
import { natXParser } "NatX";
import { optionParser; nullParser } "Option";
import { principalParser } "Principal";
import { recordParser } "Record";
import { textParser } "Text";
import { variantParser } "Variant";

module CandidParser {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    type Parser<T, A> = P.Parser<T, A>;

    public func parse(text : Text) : [Candid] {
        let chars = Iter.toList(text.chars());

        switch (parseCandid(chars)) {
            case (?candid) candid;
            case (null) Debug.trap("Failed to parse Candid text from input: " # debug_show (chars));
        };
    };

    func parseCandid(l : List.List<Char>) : ?[Candid] {
        switch (multiValueCandidParser()(l)) {
            case (null) { null };
            case (?(x, xs)) {
                switch (xs) {
                    case (null) { ?x };
                    case (_xs) {
                        Debug.print("Failed to parse Candid: " # debug_show (x, _xs));
                        null;
                    };
                };
            };
        };
    };

    public func multiValueCandidParser() : Parser<Char, [Candid]> {
        C.bracket(
            C.String.string("("),
            C.map(
                C.sepBy(
                    ignoreSpace(candidParser()),
                    ignoreSpace(C.Character.char(',')),
                ),
                func(list : List<Candid>) : [Candid] {
                    List.toArray(list);
                },
            ),
            ignoreSpace(C.String.string(")")),
        );
    };

    public func candidParser() : Parser<Char, Candid> {
        let supportedParsers = [
            intXParser(),
            natXParser(),

            intParser(),
            natParser(),

            textParser(),

            blobParser(),
            arrayParser(candidParser),
            optionParser(candidParser),
            recordParser(candidParser),
            variantParser(candidParser),
            boolParser(),
            principalParser(),
            floatParser(),
            nullParser(),
            bracketParser(candidParser)
        ];

        C.oneOf([
            C.bracket(
                ignoreSpace(C.String.string("(")),
                ignoreSpace(C.oneOf(supportedParsers)),
                ignoreSpace(C.String.string(")")),
            ),
            C.bracket(
                C.many(C.Character.space()),
                C.oneOf(supportedParsers),
                C.many(C.Character.space()),
            ),
        ]);
    };

    func bracketParser(parser : () -> Parser<Char, Candid>) : Parser<Char, Candid> {
        C.bracket(
            ignoreSpace(C.String.string("(")),
            ignoreSpace(P.delay(parser)),
            ignoreSpace(C.String.string(")")),
        )
    };
};
