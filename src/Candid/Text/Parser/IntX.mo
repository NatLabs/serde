import Debug "mo:core/Debug";
import List "mo:core/pure/List";
import Int8 "mo:core/Int8";
import Int16 "mo:core/Int16";
import Int32 "mo:core/Int32";
import Int64 "mo:core/Int64";

import C "../../../../submodules/parser-combinators.mo/src/Combinators";
import P "../../../../submodules/parser-combinators.mo/src/Parser";

import Candid "../../Types";
import { ignoreSpace } "Common";
import { parseInt } "Int";

module {
    type Candid = Candid.Candid;
    type List<A> = List.List<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public func intXParser() : Parser<Char, Candid> {
        C.map(
            parseIntX(),
            func((int, intType) : (Int, Text)) : Candid {
                switch (intType) {
                    case ("int") #Int(int);
                    case ("int8") #Int8(Int8.fromInt(int));
                    case ("int16") #Int16(Int16.fromInt(int));
                    case ("int32") #Int32(Int32.fromInt(int));
                    case ("int64") #Int64(Int64.fromInt(int));
                    case (_) Debug.trap("Only int8, int16, int32, int64 int bit types but got '" # intType # "'");
                };
            },
        );
    };

    func parseIntX() : Parser<Char, (Int, Text)> {
        C.seq(
            ignoreSpace(
                parseInt()
            ),
            C.right(
                ignoreSpace(
                    C.Character.char(':')
                ),
                ignoreSpace(
                    C.oneOf([
                        C.String.string("int64"),
                        C.String.string("int32"),
                        C.String.string("int16"),
                        C.String.string("int8"),
                        C.String.string("int"),
                    ])
                ),
            ),
        );
    };
};
