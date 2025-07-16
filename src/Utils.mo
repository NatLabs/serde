import Array "mo:base/Array";
import Char "mo:base/Char";
import Order "mo:base/Order";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Int64 "mo:base/Int64";

import Prelude "mo:base/Prelude";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Itertools "mo:itertools/Iter";

import ByteUtils "mo:byte-utils";
module {

    type Iter<A> = Iter.Iter<A>;
    type Buffer<A> = Buffer.Buffer<A>;
    type Result<A, B> = Result.Result<A, B>;

    public func reverse_order<A>(fn : (A, A) -> Order.Order) : (A, A) -> Order.Order {
        func(a : A, b : A) : Order.Order {
            switch (fn(a, b)) {
                case (#less) #greater;
                case (#equal) #equal;
                case (#greater) #less;
            };
        };
    };

    public func array_slice<A>(arr : [A], start : Nat, end : Nat) : [A] {
        Array.tabulate<A>(
            end - start,
            func(i : Nat) = arr[start + i],
        );
    };

    public func concatKeys(keys : [[Text]]) : [Text] {
        Iter.toArray(
            Itertools.flattenArray(keys)
        );
    };

    public func sized_iter_to_array<A>(iter : Iter<A>, size : Nat) : [A] {
        Array.tabulate<A>(
            size,
            func(i : Nat) {
                switch (iter.next()) {
                    case (?x) x;
                    case (_) Prelude.unreachable();
                };
            },
        );
    };

    public func send_error<OldOk, NewOk, Error>(res : Result<OldOk, Error>) : Result<NewOk, Error> {
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
            )
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

    public func isHash(key : Text) : Bool {
        Itertools.all(
            key.chars(),
            func(c : Char) : Bool {
                c == '_' or Char.isDigit(c);
            },
        );
    };

    public func text_to_nat32(text : Text) : Nat32 {
        Itertools.fold(
            text.chars(),
            0 : Nat32,
            func(acc : Nat32, c : Char) : Nat32 {
                if (c == '_') {
                    acc;
                } else {
                    acc * 10 + Char.toNat32(c) - Char.toNat32('0');
                };
            },
        );
    };

    public func text_to_nat(text : Text) : Nat {
        Itertools.fold(
            text.chars(),
            0 : Nat,
            func(acc : Nat, c : Char) : Nat {
                if (c == '_') {
                    acc;
                } else {
                    acc * 10 + Nat32.toNat(Char.toNat32(c) - Char.toNat32('0'));
                };
            },
        );
    };

    public func text_is_number(text : Text) : Bool {
        Itertools.all(
            text.chars(),
            func(c : Char) : Bool {
                Char.isDigit(c) or c == '_';
            },
        );
    };

    type AddToBuffer<A> = {
        add : (A) -> ();
    };

    // https://en.wikipedia.org/wiki/LEB128
    // limited to 64-bit unsigned integers
    // more performant than the general unsigned_leb128
    public func unsigned_leb128_64(buffer : ByteUtils.BufferLike<Nat8>, n : Nat) {
        var value = Nat64.fromNat(n);
        while (value >= 0x80) {
            buffer.add(Nat8.fromNat(Nat64.toNat(value & 0x7F)) | 0x80);
            value >>= 7;
        };
        buffer.add(Nat8.fromNat(Nat64.toNat(value)));
    };

    public func unsigned_leb128(buffer : ByteUtils.BufferLike<Nat8>, n : Nat) {
        var value = Nat64.fromNat(n);
        while (value >= 0x80) {
            buffer.add(Nat8.fromNat(Nat64.toNat(value & 0x7F)) | 0x80);
            value >>= 7;
        };
        buffer.add(Nat8.fromNat(Nat64.toNat(value)));
    };

    public func signed_leb128_64(buffer : ByteUtils.BufferLike<Nat8>, num : Int) {
        ByteUtils.Buffer.addSLEB128_64(buffer, Int64.fromInt(num));
    };

    // public func signed_leb128(buffer : AddToBuffer<Nat8>, num : Int) {
    //     let nat64_bound = 18_446_744_073_709_551_616;

    //     if (num < nat64_bound and num > -nat64_bound) return signed_leb128_64(buffer, num);

    //     var n = num;
    //     let is_negative = n < 0;

    // };

    public class ReusableBuffer<A>(init_capacity : Nat) {
        var elems : [var ?A] = Array.init(init_capacity, null);
        var count : Nat = 0;

        public func size() : Nat = count;

        public func add(elem : A) {
            if (count == elems.size()) {
                elems := Array.tabulateVar(
                    elems.size() * 2,
                    func(i : Nat) : ?A {
                        if (i < count) {
                            elems[i];
                        } else {
                            null;
                        };
                    },
                );
            };

            elems[count] := ?elem;
            count += 1;
        };

        public func clear() {
            count := 0;
        };

        public func get(i : Nat) : A {
            switch (elems[i]) {
                case (?elem) elem;
                case (null) Debug.trap "Index out of bounds";
            };
        };

        public func put(i : Nat, elem : A) {
            if (i >= count) Debug.trap "Index out of bounds";
            elems[i] := ?elem;
        };

        public func vals() : Iter.Iter<A> {
            var i = 0;

            object {
                public func next() : ?A {
                    if (i < count) {
                        let res = elems[i];
                        i += 1;
                        res;
                    } else {
                        null;
                    };
                };
            };
        };
    };

};
