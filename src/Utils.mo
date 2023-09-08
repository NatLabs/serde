import Order "mo:base/Order";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Result "mo:base/Result";

import Prelude "mo:base/Prelude";
import itertools "mo:itertools/Iter";

module {

    type Result<A, B> = Result.Result<A, B>;

    public func send_error<OldOk, NewOk, Error>(res: Result<OldOk, Error>): Result<NewOk, Error>{
        switch (res) {
            case (#ok(_)) Prelude.unreachable();
            case (#err(errorMsg)) #err(errorMsg);
        };
    };

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
