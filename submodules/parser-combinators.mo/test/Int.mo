import List "mo:base@0.7.3/List";

import C "../src/Combinators";
import L "../src/List";

let int = C.Int.int();
switch (int(L.fromText("-100"))) {
    case (null) { assert (false) };
    case (?(x, xs)) {
        assert (x == -100);
        assert (xs == null);
    };
};

let ints = C.bracket(
    C.Character.char('['),
    C.sepBy1(int, C.Character.char(',')),
    C.Character.char(']'),
);
switch (ints(L.fromText("[-100,1,15]"))) {
    case (null) { assert (false) };
    case (?(x, xs)) {
        assert (List.toArray(x) == [-100, 1, 15]);
        assert (xs == null);
    };
};
