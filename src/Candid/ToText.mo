import Float "mo:base/Float";
import Text "mo:base/Text";
import Principal "mo:base/Principal";

import Candid "Types";

import U "../Utils";

module {
    type Candid = Candid.Candid;

    public func toText(candid : Candid) : Text {
        switch (candid) {

            case (#Nat(n)) removeUnderscore(debug_show (n));
            case (#Nat8(n)) removeUnderscore(debug_show (n)) # " : nat8";
            case (#Nat16(n)) removeUnderscore(debug_show (n)) # " : nat16";
            case (#Nat32(n)) removeUnderscore(debug_show (n)) # " : nat32";
            case (#Nat64(n)) removeUnderscore(debug_show (n)) # " : nat64";

            case (#Int(n)) U.stripStart(removeUnderscore(debug_show (n)), #char '+');
            case (#Int8(n)) U.stripStart(removeUnderscore(debug_show (n)), #char '+') # " : int8";
            case (#Int16(n)) U.stripStart(removeUnderscore(debug_show (n)), #char '+') # " : int16";
            case (#Int32(n)) U.stripStart(removeUnderscore(debug_show (n)), #char '+') # " : int32";
            case (#Int64(n)) U.stripStart(removeUnderscore(debug_show (n)), #char '+') # " : int64";

            case (#Float(n)) Float.format(#exact, n);

            case (#Null) "null";
            case (#Empty) "()";
            case (#Bool(b)) debug_show (b);
            case (#Text(text)) text;

            case (#Blob(bytes)) "blob " # debug_show (bytes);
            case (#Principal(p)) "principal \"" # Principal.toText(p) # "\"";

            case (#Option(value)) "opt " # toText(value);

            case (#Array(values)) {
                var text = "vec { ";
                for (value in values.vals()) {
                    text #= toText(value) # ", ";
                };
                text #= "}";
                text;
            };

            case (#Record(fields)) {
                var text = "record { ";
                for ((key, val) in fields.vals()) {
                    text #= key # " = " # toText(val) # ", ";
                };
                text #= "}";
                text;
            };

            case (#Variant((key, val))) {
                var text = "variant { ";
                text #= key # " = " # toText(val) # ", ";

                text #= "}";
                text;
            };
        };
    };

    func removeUnderscore(text : Text) : Text {
        Text.replace(text, #text "_", "");
    };
};
