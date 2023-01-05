import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import List "mo:base/List";

import C "mo:parser-combinators/Combinators";
import P "mo:parser-combinators/Parser";

import Candid "../Types";

import { ignoreSpace; any } "Common";

import { arrayParser } "Array";
import { blobParser } "Blob";
import { boolParser } "Bool";
import { floatParser } "Float";
import { intParser } "Int";
import { intXParser } "IntX";
import { natParser } "Nat";
import { natXParser } "NatX";
import { optionParser } "Option";
import { principalParser } "Principal";
import { recordParser } "Record";
import { textParser } "Text";
import { variantParser } "Variant";

module CandidParser {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func parse(text : Text) : Candid {
        let chars = Iter.toList(text.chars());

        switch (parseCandid(chars)) {
            case (?candid) candid;
            case (null) Debug.trap("Failed to parse Candid text");
        };
    };

    func parseCandid(l : List.List<Char>) : ?Candid {
        switch (candidParser()(l)) {
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

    func candidParser() : Parser<Char, Candid> {
        let supportedParsers = [
            blobParser(),
            textParser(),
            arrayParser(candidParser),
            optionParser(candidParser),
            recordParser(candidParser),
            variantParser(candidParser),
            boolParser(),
            principalParser(),
            natParser(),
            natXParser(),
            intXParser(),
            floatParser(),
            nullParser(),
        ];

        C.oneOf([
            C.bracket(
                C.String.string("("),
                ignoreSpace(
                    C.oneOf(supportedParsers),
                ),
                ignoreSpace(C.String.string(")")),
            ),
            C.bracket(
                C.many(C.Character.space()),
                ignoreSpace(C.oneOf(supportedParsers)),
                C.many(C.Character.space()),
            ),
        ]);
    };

    func nullParser() : Parser<Char, Candid> {
        C.map(
            ignoreSpace(C.String.string("null")),
            func(_ : Text) : Candid {
                #Null;
            },
        );
    };
};