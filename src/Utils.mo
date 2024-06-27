import Array "mo:base/Array";
import Char "mo:base/Char";
import Order "mo:base/Order";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Result "mo:base/Result";

import Prelude "mo:base/Prelude";
import Nat32 "mo:base/Nat32";
import Itertools "mo:itertools/Iter";

module {

    type Iter<A> = Iter.Iter<A>;
    type Result<A, B> = Result.Result<A, B>;

    public func reverse_order<A>(fn: (A, A) ->  Order.Order): (A, A) ->  Order.Order{
        func (a: A, b: A): Order.Order {
            switch (fn(a, b)) {
                case (#less)    #greater;
                case (#equal)   #equal;
                case (#greater) #less;
            };
        };
    };

    public func array_slice<A>(arr: [A], start: Nat, end: Nat): [A] {
        Array.tabulate<A>(
            end - start,
            func (i: Nat) = arr[start + i]
        );
    };

    public func concatKeys(keys : [[Text]]) : [Text] {
        Iter.toArray(
            Itertools.flattenArray(keys)
        )
    };
    
    public func sized_iter_to_array<A>(iter: Iter<A>, size: Nat): [A] {
        Array.tabulate<A>(
            size,
            func (i: Nat){
                switch(iter.next()){
                    case (?x) x;
                    case (_) Prelude.unreachable();
                };
            }
        );
    };

    public func send_error<OldOk, NewOk, Error>(res: Result<OldOk, Error>): Result<NewOk, Error>{
        switch (res) {
            case (#ok(_)) Prelude.unreachable();
            case (#err(errorMsg)) #err(errorMsg);
        };
    };

    public func subText(text : Text, start : Nat, end : Nat) : Text {
        Itertools.toText(
            Itertools.skip(
                Itertools.take(text.chars(), end),
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

    public func isHash(key: Text): Bool {
        Itertools.all(
            key.chars(),
            func(c: Char): Bool {
                c == '_' or Char.isDigit(c);
            },
        )
    };

    public func text_to_nat32(text : Text) : Nat32 {
        Itertools.fold(
            text.chars(),
            0 : Nat32,
            func (acc : Nat32, c : Char) : Nat32 {
                if( c == '_') {
                    acc
                } else {
                    acc * 10 + Char.toNat32(c) - Char.toNat32('0');
                };
            },
        );
    };

    public func text_to_nat(text: Text): Nat {
        Itertools.fold(
            text.chars(),
            0 : Nat,
            func (acc : Nat, c : Char) : Nat {
                if( c == '_') {
                    acc
                } else {
                    acc * 10 + Nat32.toNat(Char.toNat32(c) - Char.toNat32('0'));
                };
            },
        );
    };

    public func text_is_number(text: Text): Bool {
        Itertools.all(
            text.chars(),
            func(c: Char): Bool {
                Char.isDigit(c) or c == '_';
            },
        )
    };

};
