import Itertools "mo:Itertools/Iter";

module {
    public func subText(text : Text, start : Nat, end : Nat) : Text {
        Itertools.toText(
            Itertools.skip(
                Itertools.take(text.chars(), end),
                start,
            ),
        );
    };
};
