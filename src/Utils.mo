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

import Prelude "mo:base/Prelude";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Itertools "mo:itertools/Iter";

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
    public func unsigned_leb128_64(buffer : AddToBuffer<Nat8>, n : Nat) {
        var n64 : Nat64 = Nat64.fromNat(n);

        loop {
            var byte = n64 & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
            n64 >>= 7;

            if (n64 > 0) byte := (byte | 0x80);
            buffer.add(byte);

        } while (n64 > 0);
    };

    public func unsigned_leb128(buffer : AddToBuffer<Nat8>, n : Nat) {
        let nat64_bound = 18_446_744_073_709_551_616;

        if (n < nat64_bound) {
            // more performant than the general unsigned_leb128
            var n64 : Nat64 = Nat64.fromNat(n);

            loop {
                var byte = n64 & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
                n64 >>= 7;

                if (n64 > 0) byte := (byte | 0x80);
                buffer.add(byte);

            } while (n64 > 0);

            return;
        };

        var num = n;

        loop {
            var byte = num % 0x80 |> Nat8.fromNat(_);
            num /= 0x80;

            if (num > 0) byte := (byte | 0x80);
            buffer.add(byte);

        } while (num > 0);
    };

    public func signed_leb128_64(buffer : AddToBuffer<Nat8>, num : Int) {

        let is_negative = num < 0;

        // because we extract bytes in multiple of 7 bits
        // to extract the 64th bit we pad the number with 6 extra bits
        // to make it 70 which is a multiple of 7
        // however, because nat64 is bounded by 64 bits
        // the extra 6 bits are not flipped which leads to an incorrect result

        let nat64_bound = 18_446_744_073_709_551_616;

        if (Int.abs(num) < nat64_bound) {
            var n64 = Nat64.fromNat(Int.abs(num));

            let bit_length = Nat64.toNat(64 - Nat64.bitcountLeadingZero(n64));
            var n7bits = (bit_length / 7) + 1;
            if (is_negative) n64 := Nat64.fromNat(Int.abs(num) - 1);

            loop {
                var word = if (is_negative) ^n64 else n64;
                var byte = word & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
                n64 >>= 7;
                n7bits -= 1;

                if (n7bits > 0) byte := (byte | 0x80);
                buffer.add(byte);

            } while (n7bits > 0);
            return;
        };

        Debug.trap("numbers greater than 18_446_744_073_709_551_616 are not supported");

        var n = Int.abs(num);

        loop {
            var word = if (is_negative) ^Nat8.fromNat(n % 0x80) & 0x7f else Nat8.fromNat(n % 0x80) & 0x7f;
            var byte = word;
            n /= 0x80;

            if (n > 0) { byte := (byte | 0x80) } else {
                if (is_negative) byte := byte +% 1;
            };
            buffer.add(byte);

        } while (n > 0);

        // buffer.add(if (is_negative) 0x7f else 0x00);

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
