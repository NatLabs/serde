import Order "mo:base/Order";
import Float "mo:base/Float";
import Text "mo:base/Text";

import itertools "mo:itertools/Iter";

module {
    public func subText(text : Text, start : Nat, end : Nat) : Text {
        itertools.toText(
            itertools.skip(
                itertools.take(text.chars(), end),
                start,
            ),
        );
    };

    public func cmpRecords(a : (Text, Any), b : (Text, Any)) : Order.Order {
        Text.compare(a.0, b.0);
    };

    public func stripStart(text : Text, prefix : Text.Pattern) : Text {
        switch (Text.stripStart(text, prefix)) {
            case (?t) t;
            case (_) text;
        };
    };

    public func log2(n : Float) : Float {
        Float.log(n) / Float.log(2);
    };
};
