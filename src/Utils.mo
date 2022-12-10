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
};
