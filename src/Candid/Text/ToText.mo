import Float "mo:base/Float";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";

import Itertools "mo:itertools/Iter";

import CandidType "../Types";

import U "../../Utils";

module {
    type Candid = CandidType.Candid;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    public func toText(candid_values : [Candid]) : Text {
        var text = "";

        let candid_iter = Itertools.peekable(candid_values.vals());

        for (val in candid_iter) {
            if (candid_iter.peek() == null){
                text #= candidToText(val, );
            } else {
                text #= candidToText(val) # ", ";
            };
        };

        if (candid_values.size() == 1 and Text.startsWith(text, #text("("))){
            text
        } else {
             "(" # text # ")"
        };
    };


    func candidToText(candid: Candid): Text{
        switch (candid) {
            case (#Nat(n)) removeUnderscore(debug_show (n));
            case (#Nat8(n)) addBrackets(removeUnderscore(debug_show (n)) # " : nat8");
            case (#Nat16(n)) addBrackets(removeUnderscore(debug_show (n)) # " : nat16");
            case (#Nat32(n)) addBrackets(removeUnderscore(debug_show (n)) # " : nat32");
            case (#Nat64(n)) addBrackets(removeUnderscore(debug_show (n)) # " : nat64");

            case (#Int(n)) U.stripStart(removeUnderscore(debug_show (n)), #char '+');
            case (#Int8(n)) addBrackets(U.stripStart(removeUnderscore(debug_show (n)), #char '+') # " : int8");
            case (#Int16(n)) addBrackets(U.stripStart(removeUnderscore(debug_show (n)), #char '+') # " : int16");
            case (#Int32(n)) addBrackets(U.stripStart(removeUnderscore(debug_show (n)), #char '+') # " : int32");
            case (#Int64(n)) addBrackets(U.stripStart(removeUnderscore(debug_show (n)), #char '+') # " : int64");

            case (#Float(n)) Float.format(#exact, n);

            case (#Null) "null";
            case (#Empty) "()";
            case (#Bool(b)) debug_show (b);
            case (#Text(text)) "\"" # text # "\"";

            case (#Blob(bytes)) "blob " # debug_show (bytes);
            case (#Principal(p)) "principal \"" # Principal.toText(p) # "\"";

            case (#Option(value)) "opt (" # candidToText(value) # ")";

            case (#Array(values)) {
                var text = "vec { ";

                for (value in values.vals()) {
                    text #= candidToText(value) # "; ";
                };

                text # "}";
            };

            case (#Record(fields) or #Map(fields)) {
                var text = "record { ";

                for ((key, val) in fields.vals()) {
                    text #= key # " = " # candidToText(val) # "; ";
                };

                text # "}";
            };

            case (#Variant((key, val))) {
                "variant { " # key # " = " # candidToText(val) # " }";
            };
        };
    };

    func removeUnderscore(text : Text) : Text {
        Text.replace(text, #text "_", "");
    };

    func addBrackets(text : Text) : Text {
        "(" # text # ")";
    };
};
