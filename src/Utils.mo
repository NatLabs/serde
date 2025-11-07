import Array "mo:base@0.16.0/Array";
import Char "mo:base@0.16.0/Char";
import Order "mo:base@0.16.0/Order";
import Float "mo:base@0.16.0/Float";
import Text "mo:base@0.16.0/Text";
import Iter "mo:base@0.16.0/Iter";
import Nat64 "mo:base@0.16.0/Nat64";
import Nat32 "mo:base@0.16.0/Nat32";
import Nat8 "mo:base@0.16.0/Nat8";
import Int "mo:base@0.16.0/Int";
import Buffer "mo:base@0.16.0/Buffer";
import Result "mo:base@0.16.0/Result";
import Int64 "mo:base@0.16.0/Int64";
import Blob "mo:base@0.16.0/Blob";

import Prelude "mo:base@0.16.0/Prelude";
import Debug "mo:base@0.16.0/Debug";
import Itertools "mo:itertools@0.2.2/Iter";
import Map "mo:map@9.0.1/Map";
import MapConst "mo:map@9.0.1/Map/const";

import ByteUtils "mo:byte-utils@0.1.2";

module {

    type Iter<A> = Iter.Iter<A>;
    type Buffer<A> = Buffer.Buffer<A>;
    type Result<A, B> = Result.Result<A, B>;

    public func create_map<K, V>(map_size : Nat) : Map.Map<K, V> = [
        var ?(
            Array.init<?K>(map_size, null),
            Array.init<?V>(map_size, null),
            Array.init<Nat>(map_size * 2, MapConst.NULL),
            Array.init<Nat32>(3, 0),
        )
    ];

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
