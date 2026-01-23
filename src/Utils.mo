import Array "mo:core/Array";
import Char "mo:core/Char";
import Order "mo:core/Order";
import VarArray "mo:core/VarArray";
import Float "mo:core/Float";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Nat64 "mo:core/Nat64";
import Nat32 "mo:core/Nat32";
import Nat8 "mo:core/Nat8";
import Int "mo:core/Int";
import List "mo:core/List";
import Result "mo:core/Result";
import Int64 "mo:core/Int64";
import Blob "mo:core/Blob";
import Debug "mo:core/Debug";
import Runtime "mo:core/Runtime";
import Itertools "mo:itertools@0.2.2/Iter";

import ByteUtils "mo:byte-utils@0.1.2";

module {

    type Iter<A> = Iter.Iter<A>;
    type List<A> = List.List<A>;
    type Result<A, B> = Result.Result<A, B>;

    /// Function copied from mo:candid/Tag: https://github.com/edjCase/motoko_candid/blob/d038b7bd953fb8826ae66a5f34bf06dcc29b2e0f/src/Tag.mo#L14-L30
    ///
    /// Computes the hash of a given record field key.
    ///
    public func hash_record_key(name : Text) : Nat32 {
        // hash(name) = ( Sum_(i=0..k) utf8(name)[i] * 223^(k-i) ) mod 2^32 where k = |utf8(name)|-1
        let bytes : [Nat8] = Blob.toArray(Text.encodeUtf8(name));
        Array.foldLeft<Nat8, Nat32>(
            bytes,
            0,
            func(accum : Nat32, byte : Nat8) : Nat32 {
                (accum *% 223) +% Nat32.fromNat(Nat8.toNat(byte));
            },
        );
    };

    public func reverse_order<A>(fn : (A, A) -> Order.Order) : (A, A) -> Order.Order {
        func(a : A, b : A) : Order.Order {
            switch (fn(a, b)) {
                case (#less) #greater;
                case (#equal) #equal;
                case (#greater) #less;
            };
        };
    };

    public type ArrayLike<A> = {
        size : () -> Nat;
        get : (Nat) -> A;
    };

    public func array_slice<A>(arr : ArrayLike<A>, start : Nat, end : Nat) : [A] {
        Array.tabulate<A>(
            end - start,
            func(i : Nat) = arr.get(start + i),
        );
    };

    public func blob_slice(blob : Blob, start : Nat, end : Nat) : [Nat8] {
        Array.tabulate<Nat8>(
            end - start,
            func(i : Nat) = blob.get(start + i),
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
                    case (_) Runtime.unreachable();
                };
            },
        );
    };

    public func send_error<OldOk, NewOk, Error>(res : Result<OldOk, Error>) : Result<NewOk, Error> {
        switch (res) {
            case (#ok(_)) Runtime.unreachable();
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
        var elems : [var ?A] = VarArray.repeat(null, init_capacity);
        var count : Nat = 0;

        public func size() : Nat = count;

        public func add(elem : A) {
            if (count == elems.size()) {
                elems := VarArray.tabulate(
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
                case (null) Runtime.trap "Index out of bounds";
            };
        };

        public func put(i : Nat, elem : A) {
            if (i >= count) Runtime.trap "Index out of bounds";
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

    /// Wrapper class that provides a Buffer-like interface around mo:core/List
    public class ListBuffer<A>() {
        let list = List.empty<A>();

        public func size() : Nat = List.size(list);

        public func add(elem : A) = List.add(list, elem);

        public func clear() = List.clear(list);

        public func get(i : Nat) : A {
            switch (List.get(list, i)) {
                case (?elem) elem;
                case (null) Runtime.trap "Index out of bounds";
            };
        };

        public func put(i : Nat, elem : A) = List.put(list, i, elem);

        public func vals() : Iter.Iter<A> = List.values(list);

        public func toArray() : [A] = List.toArray(list);

        public func removeLast() : ?A = List.removeLast(list);
    };

    /// Buffer module that provides a compatible API with mo:base/Buffer but uses mo:core/List
    public module Buffer {
        public type Buffer<A> = ListBuffer<A>;

        public func Buffer<A>(initCapacity : Nat) : ListBuffer<A> = ListBuffer<A>();

        public func toArray<A>(buffer : ListBuffer<A>) : [A] = buffer.toArray();

        public func fromArray<A>(arr : [A]) : ListBuffer<A> {
            let buf = ListBuffer<A>();
            for (elem in arr.vals()) {
                buf.add(elem);
            };
            buf;
        };

        public func last<A>(buffer : ListBuffer<A>) : ?A {
            let s = buffer.size();
            if (s == 0) {
                null;
            } else {
                ?buffer.get(s - 1);
            };
        };
    };

};
