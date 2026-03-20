import Prim "mo:prim";

import Iter "mo:core/Iter";
import Array "mo:core/Array";
import List "mo:core/List";
import Nat8 "mo:core/Nat8";
import Nat16 "mo:core/Nat16";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import Int8 "mo:core/Int8";
import Int16 "mo:core/Int16";
import Int32 "mo:core/Int32";
import Int64 "mo:core/Int64";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Runtime "mo:core/Runtime";

import FloatX "mo:xtended-numbers@2.3.0/FloatX";

module ByteUtils {
    /// An iterator of bytes.
    type Bytes = Iter.Iter<Nat8>;

    func to_nat8(bytes : Bytes) : Nat8 {
        switch (bytes.next()) {
            case (?byte) { byte };
            case (_) { Runtime.trap("ByteUtils: out of bounds") };
        };
    };

    public type BufferLike<A> = {
        add : (A) -> ();
        put : (Nat, A) -> ();
        get : (Nat) -> A;
        size : () -> Nat;
    };

    class ListBuffer<A>() {
        let list = List.empty<A>();
        public func size() : Nat = List.size(list);
        public func add(elem : A) = List.add(list, elem);
        public func get(i : Nat) : A {
            switch (List.get(list, i)) {
                case (?elem) elem;
                case (null) Runtime.trap("ByteUtils: ListBuffer index out of bounds");
            };
        };
        public func put(i : Nat, elem : A) = List.put(list, i, elem);
        public func toArray() : [A] = List.toArray(list);
    };

    public type Functions = module {
        toNat8 : (Bytes) -> Nat8;
        toNat16 : (Bytes) -> Nat16;
        toNat32 : (Bytes) -> Nat32;
        toNat64 : (Bytes) -> Nat64;
        toInt8 : (Bytes) -> Int8;
        toInt16 : (Bytes) -> Int16;
        toInt32 : (Bytes) -> Int32;
        toInt64 : (Bytes) -> Int64;
        toFloat : (Bytes) -> Float;

        fromNat8 : (Nat8) -> [Nat8];
        fromNat16 : (Nat16) -> [Nat8];
        fromNat32 : (Nat32) -> [Nat8];
        fromNat64 : (Nat64) -> [Nat8];
        fromInt8 : (Int8) -> [Nat8];
        fromInt16 : (Int16) -> [Nat8];
        fromInt32 : (Int32) -> [Nat8];
        fromInt64 : (Int64) -> [Nat8];
        fromFloat : (Float) -> [Nat8];
    };

    public module LittleEndian {

        public func toNat8(bytes : Bytes) : Nat8 {
            to_nat8(bytes);
        };

        public func toNat16(bytes : Bytes) : Nat16 {
            let low = to_nat8(bytes);
            let high = to_nat8(bytes);
            Nat16.fromNat8(low) | Nat16.fromNat8(high) << 8;
        };

        public func toNat32(bytes : Bytes) : Nat32 {
            let b1 = to_nat8(bytes);
            let b2 = to_nat8(bytes);
            let b3 = to_nat8(bytes);
            let b4 = to_nat8(bytes);

            Nat32.fromNat(Nat8.toNat(b1)) | Nat32.fromNat(Nat8.toNat(b2)) << 8 | Nat32.fromNat(Nat8.toNat(b3)) << 16 | Nat32.fromNat(Nat8.toNat(b4)) << 24;

        };

        public func toNat64(bytes : Bytes) : Nat64 {
            let b1 = to_nat8(bytes);
            let b2 = to_nat8(bytes);
            let b3 = to_nat8(bytes);
            let b4 = to_nat8(bytes);
            let b5 = to_nat8(bytes);
            let b6 = to_nat8(bytes);
            let b7 = to_nat8(bytes);
            let b8 = to_nat8(bytes);

            Nat64.fromNat(Nat8.toNat(b1)) | Nat64.fromNat(Nat8.toNat(b2)) << 8 | Nat64.fromNat(Nat8.toNat(b3)) << 16 | Nat64.fromNat(Nat8.toNat(b4)) << 24 | Nat64.fromNat(Nat8.toNat(b5)) << 32 | Nat64.fromNat(Nat8.toNat(b6)) << 40 | Nat64.fromNat(Nat8.toNat(b7)) << 48 | Nat64.fromNat(Nat8.toNat(b8)) << 56;

        };

        public func toInt8(bytes : Bytes) : Int8 {
            Int8.fromNat8(to_nat8(bytes));
        };

        public func toInt16(bytes : Bytes) : Int16 {
            let nat16 = toNat16(bytes);
            Int16.fromNat16(nat16);
        };

        public func toInt32(bytes : Bytes) : Int32 {
            let nat32 = toNat32(bytes);
            Int32.fromNat32(nat32);
        };

        public func toInt64(bytes : Bytes) : Int64 {
            let nat64 = toNat64(bytes);
            Int64.fromNat64(nat64);
        };

        public func toFloat(bytes : Bytes) : Float {
            let ?fx = FloatX.fromBytes(bytes, #f64, #lsb) else Runtime.trap("ByteUtils: failed to decode Float");
            FloatX.toFloat(fx);
        };

        public func fromNat8(n : Nat8) : [Nat8] {
            [n];
        };

        public func fromNat16(n : Nat16) : [Nat8] {
            let bytes = Prim.explodeNat16(n);
            [bytes.1, bytes.0];
        };

        public func fromNat32(n : Nat32) : [Nat8] {
            let bytes = Prim.explodeNat32(n);
            [bytes.3, bytes.2, bytes.1, bytes.0];
        };

        public func fromNat64(n : Nat64) : [Nat8] {
            let bytes = Prim.explodeNat64(n);
            [bytes.7, bytes.6, bytes.5, bytes.4, bytes.3, bytes.2, bytes.1, bytes.0];
        };

        public func fromInt8(i : Int8) : [Nat8] {
            [Int8.toNat8(i)];
        };

        public func fromInt16(i : Int16) : [Nat8] {
            let nat16 = Int16.toNat16(i);
            fromNat16(nat16);
        };

        public func fromInt32(i : Int32) : [Nat8] {
            let nat32 = Int32.toNat32(i);
            fromNat32(nat32);
        };

        public func fromInt64(i : Int64) : [Nat8] {
            let nat64 = Int64.toNat64(i);
            fromNat64(nat64);
        };

        public func fromFloat(f : Float) : [Nat8] {
            let fx = FloatX.fromFloat(f, #f64);
            let buffer = ListBuffer<Nat8>();

            FloatX.toBytesBuffer({ write = buffer.add }, fx, #lsb);
            buffer.toArray();
        };

    };

    public module BigEndian {
        public func toNat8(bytes : Bytes) : Nat8 {
            to_nat8(bytes);
        };

        public func toNat16(bytes : Bytes) : Nat16 {
            let high = to_nat8(bytes);
            let low = to_nat8(bytes);
            Nat16.fromNat8(high) << 8 | Nat16.fromNat8(low);
        };

        public func toNat32(bytes : Bytes) : Nat32 {
            let b1 = to_nat8(bytes);
            let b2 = to_nat8(bytes);
            let b3 = to_nat8(bytes);
            let b4 = to_nat8(bytes);

            Nat32.fromNat(Nat8.toNat(b1)) << 24 | Nat32.fromNat(Nat8.toNat(b2)) << 16 | Nat32.fromNat(Nat8.toNat(b3)) << 8 | Nat32.fromNat(Nat8.toNat(b4));
        };

        public func toNat64(bytes : Bytes) : Nat64 {
            let b1 = to_nat8(bytes);
            let b2 = to_nat8(bytes);
            let b3 = to_nat8(bytes);
            let b4 = to_nat8(bytes);
            let b5 = to_nat8(bytes);
            let b6 = to_nat8(bytes);
            let b7 = to_nat8(bytes);
            let b8 = to_nat8(bytes);

            Nat64.fromNat(Nat8.toNat(b1)) << 56 | Nat64.fromNat(Nat8.toNat(b2)) << 48 | Nat64.fromNat(Nat8.toNat(b3)) << 40 | Nat64.fromNat(Nat8.toNat(b4)) << 32 | Nat64.fromNat(Nat8.toNat(b5)) << 24 | Nat64.fromNat(Nat8.toNat(b6)) << 16 | Nat64.fromNat(Nat8.toNat(b7)) << 8 | Nat64.fromNat(Nat8.toNat(b8));
        };

        public func toInt8(bytes : Bytes) : Int8 {
            Int8.fromNat8(to_nat8(bytes));
        };

        public func toInt16(bytes : Bytes) : Int16 {
            let nat16 = toNat16(bytes);
            Int16.fromNat16(nat16);
        };

        public func toInt32(bytes : Bytes) : Int32 {
            let nat32 = toNat32(bytes);
            Int32.fromNat32(nat32);
        };

        public func toInt64(bytes : Bytes) : Int64 {
            let nat64 = toNat64(bytes);
            Int64.fromNat64(nat64);
        };

        public func toFloat(bytes : Bytes) : Float {
            let ?fx = FloatX.fromBytes(bytes, #f64, #msb) else Runtime.trap("ByteUtils: failed to decode Float");
            FloatX.toFloat(fx);
        };

        public func fromNat8(n : Nat8) : [Nat8] {
            [n];
        };

        public func fromNat16(n : Nat16) : [Nat8] {
            let bytes = Prim.explodeNat16(n);
            [bytes.0, bytes.1];
        };

        public func fromNat32(n : Nat32) : [Nat8] {
            let bytes = Prim.explodeNat32(n);
            [bytes.0, bytes.1, bytes.2, bytes.3];
        };

        public func fromNat64(n : Nat64) : [Nat8] {
            let bytes = Prim.explodeNat64(n);
            [bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5, bytes.6, bytes.7];
        };

        public func fromInt8(i : Int8) : [Nat8] {
            [Int8.toNat8(i)];
        };

        public func fromInt16(i : Int16) : [Nat8] {
            let nat16 = Int16.toNat16(i);
            fromNat16(nat16);
        };

        public func fromInt32(i : Int32) : [Nat8] {
            let nat32 = Int32.toNat32(i);
            fromNat32(nat32);
        };

        public func fromInt64(i : Int64) : [Nat8] {
            let nat64 = Int64.toNat64(i);
            fromNat64(nat64);
        };

        public func fromFloat(f : Float) : [Nat8] {
            let fx = FloatX.fromFloat(f, #f64);
            let buffer = ListBuffer<Nat8>();

            FloatX.toBytesBuffer({ write = buffer.add }, fx, #msb);
            buffer.toArray();
        };

    };

    public module Sorted {
        // For sortable encodings, we need to use big-endian for most types
        // since lexicographical byte order matches numeric order only in big-endian

        public func fromNat8(n : Nat8) : [Nat8] {
            [n];
        };

        public func fromNat16(n : Nat16) : [Nat8] {
            // Use big-endian for sortable encoding
            let bytes = Prim.explodeNat16(n);
            [bytes.0, bytes.1];
        };

        public func fromNat32(n : Nat32) : [Nat8] {
            // Use big-endian for sortable encoding
            let bytes = Prim.explodeNat32(n);
            [bytes.0, bytes.1, bytes.2, bytes.3];
        };

        public func fromNat64(n : Nat64) : [Nat8] {
            // Use big-endian for sortable encoding
            let bytes = Prim.explodeNat64(n);
            [bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5, bytes.6, bytes.7];
        };

        public func fromInt8(i : Int8) : [Nat8] {
            // Flip sign bit to make negative numbers sort before positive
            let byte = Int8.toNat8(i);
            [byte ^ 0x80];
        };

        public func fromInt16(i : Int16) : [Nat8] {
            // Flip sign bit and use big-endian
            let nat16 = Int16.toNat16(i);
            let bytes = Prim.explodeNat16(nat16);
            [bytes.0 ^ 0x80, bytes.1];
        };

        public func fromInt32(i : Int32) : [Nat8] {
            // Flip sign bit and use big-endian
            let nat32 = Int32.toNat32(i);
            let bytes = Prim.explodeNat32(nat32);
            [bytes.0 ^ 0x80, bytes.1, bytes.2, bytes.3];
        };

        public func fromInt64(i : Int64) : [Nat8] {
            // Flip sign bit and use big-endian
            let nat64 = Int64.toNat64(i);
            let bytes = Prim.explodeNat64(nat64);
            [bytes.0 ^ 0x80, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5, bytes.6, bytes.7];
        };

        public func fromFloat(f : Float) : [Nat8] {
            // IEEE-754 sortable encoding
            let fx = FloatX.fromFloat(f, #f64);
            let buffer = ListBuffer<Nat8>();
            FloatX.toBytesBuffer({ write = buffer.add }, fx, #msb); // Use big-endian

            let bytes = buffer.toArray();

            if (f < 0.0) {
                // For negative numbers, flip all bits
                Array.tabulate<Nat8>(buffer.size(), func(i : Nat) : Nat8 { ^(bytes[i]) });
            } else {
                // For positive numbers, flip only the sign bit
                Array.tabulate<Nat8>(
                    buffer.size(),
                    func(i : Nat) : Nat8 {
                        if (i == 0) {
                            return bytes[i] ^ 0x80; // Flip sign bit only for first byte
                        } else {
                            return bytes[i]; // Keep other bytes unchanged
                        };
                    },
                );

            };
        };

        // Decoding functions
        public func toNat8(bytes : Bytes) : Nat8 {
            to_nat8(bytes);
        };

        public func toNat16(bytes : Bytes) : Nat16 {
            // Decode from big-endian
            let high = to_nat8(bytes);
            let low = to_nat8(bytes);
            Nat16.fromNat8(high) << 8 | Nat16.fromNat8(low);
        };

        public func toNat32(bytes : Bytes) : Nat32 {
            // Decode from big-endian
            let b1 = to_nat8(bytes);
            let b2 = to_nat8(bytes);
            let b3 = to_nat8(bytes);
            let b4 = to_nat8(bytes);
            Nat32.fromNat(Nat8.toNat(b1)) << 24 | Nat32.fromNat(Nat8.toNat(b2)) << 16 | Nat32.fromNat(Nat8.toNat(b3)) << 8 | Nat32.fromNat(Nat8.toNat(b4));
        };

        public func toNat64(bytes : Bytes) : Nat64 {
            // Decode from big-endian
            let b1 = to_nat8(bytes);
            let b2 = to_nat8(bytes);
            let b3 = to_nat8(bytes);
            let b4 = to_nat8(bytes);
            let b5 = to_nat8(bytes);
            let b6 = to_nat8(bytes);
            let b7 = to_nat8(bytes);
            let b8 = to_nat8(bytes);
            Nat64.fromNat(Nat8.toNat(b1)) << 56 | Nat64.fromNat(Nat8.toNat(b2)) << 48 | Nat64.fromNat(Nat8.toNat(b3)) << 40 | Nat64.fromNat(Nat8.toNat(b4)) << 32 | Nat64.fromNat(Nat8.toNat(b5)) << 24 | Nat64.fromNat(Nat8.toNat(b6)) << 16 | Nat64.fromNat(Nat8.toNat(b7)) << 8 | Nat64.fromNat(Nat8.toNat(b8));
        };

        public func toInt8(bytes : Bytes) : Int8 {
            // Flip sign bit back and decode
            let byte = to_nat8(bytes) ^ 0x80;
            Int8.fromNat8(byte);
        };

        public func toInt16(bytes : Bytes) : Int16 {
            // Flip sign bit back and decode from big-endian
            let b1 = to_nat8(bytes) ^ 0x80;
            let b2 = to_nat8(bytes);
            let nat16 = Nat16.fromNat8(b1) << 8 | Nat16.fromNat8(b2);
            Int16.fromNat16(nat16);
        };

        public func toInt32(bytes : Bytes) : Int32 {
            // Flip sign bit back and decode from big-endian
            let b1 = to_nat8(bytes) ^ 0x80;
            let b2 = to_nat8(bytes);
            let b3 = to_nat8(bytes);
            let b4 = to_nat8(bytes);
            let nat32 = Nat32.fromNat(Nat8.toNat(b1)) << 24 | Nat32.fromNat(Nat8.toNat(b2)) << 16 | Nat32.fromNat(Nat8.toNat(b3)) << 8 | Nat32.fromNat(Nat8.toNat(b4));
            Int32.fromNat32(nat32);
        };

        public func toInt64(bytes : Bytes) : Int64 {
            // Flip sign bit back and decode from big-endian
            let b1 = to_nat8(bytes) ^ 0x80;
            let b2 = to_nat8(bytes);
            let b3 = to_nat8(bytes);
            let b4 = to_nat8(bytes);
            let b5 = to_nat8(bytes);
            let b6 = to_nat8(bytes);
            let b7 = to_nat8(bytes);
            let b8 = to_nat8(bytes);
            let nat64 = Nat64.fromNat(Nat8.toNat(b1)) << 56 | Nat64.fromNat(Nat8.toNat(b2)) << 48 | Nat64.fromNat(Nat8.toNat(b3)) << 40 | Nat64.fromNat(Nat8.toNat(b4)) << 32 | Nat64.fromNat(Nat8.toNat(b5)) << 24 | Nat64.fromNat(Nat8.toNat(b6)) << 16 | Nat64.fromNat(Nat8.toNat(b7)) << 8 | Nat64.fromNat(Nat8.toNat(b8));
            Int64.fromNat64(nat64);
        };

        public func toFloat(bytes : Bytes) : Float {
            // Decode IEEE-754 sortable encoding
            let b1 = to_nat8(bytes);
            let isNegative = (b1 & 0x80) == 0x00; // If sign bit is 0, the value is negative because we flipped it during encoding

            let decodedBytes = if (isNegative) {
                // For negative numbers, flip all bits back

                Array.tabulate<Nat8>(
                    8,
                    func(i) {
                        ^(if (i == 0) b1 else to_nat8(bytes));
                    },
                );
            } else {
                // For positive numbers, flip only the sign bit back
                let remaining = Array.tabulate<Nat8>(
                    8,
                    func(i) {
                        if (i == 0) b1 ^ 0x80 else to_nat8(bytes);
                    },
                );
            };

            let ?fx = FloatX.fromBytes(decodedBytes.vals(), #f64, #msb) else Runtime.trap("ByteUtils: failed to decode Float");
            FloatX.toFloat(fx);
        };
    };

    public let LE = LittleEndian;
    public let BE = BigEndian;

    /// Encodes a `Nat64` into ULEB128 format.
    public func toLEB128_64(n64 : Nat64) : [Nat8] {
        let buffer = ListBuffer<Nat8>();
        Buffer.addLEB128_64(buffer, n64);
        buffer.toArray();
    };

    /// Decodes a ULEB128-encoded `Nat64` from a byte iterator.
    /// Traps if end of buffer is reached before value is completely decoded.
    public func fromLEB128_64(bytes : Bytes) : Nat64 {
        let buffer = ListBuffer<Nat8>();
        for (byte in bytes) { buffer.add(byte) };
        Buffer.readLEB128_64(buffer);
    };

    /// Encodes a `Nat` into ULEB128 format.
    public func toLEB128(n : Nat) : [Nat8] {
        let buffer = ListBuffer<Nat8>();
        Buffer.addLEB128_nat(buffer, n);
        buffer.toArray();
    };

    /// Decodes a ULEB128-encoded `Nat` from a byte iterator.
    /// Traps if end of buffer is reached before value is completely decoded.
    public func fromLEB128(bytes : Bytes) : Nat {
        let buffer = ListBuffer<Nat8>();
        for (byte in bytes) { buffer.add(byte) };
        Buffer.readLEB128_nat(buffer);
    };

    /// Encodes an `Int64` into SLEB128 format.
    public func toSLEB128_64(n : Int64) : [Nat8] {
        let buffer = ListBuffer<Nat8>();
        Buffer.addSLEB128_64(buffer, n);
        buffer.toArray();
    };

    /// Decodes an SLEB128-encoded `Int64` from a byte iterator.
    /// Traps if end of buffer is reached before value is completely decoded.
    public func fromSLEB128_64(bytes : Bytes) : Int64 {
        let buffer = ListBuffer<Nat8>();
        for (byte in bytes) { buffer.add(byte) };
        Buffer.readSLEB128_64(buffer);
    };

    /// Encodes an `Int` into SLEB128 format.
    public func toSLEB128(n : Int) : [Nat8] {
        let buffer = ListBuffer<Nat8>();
        Buffer.addSLEB128_int(buffer, n);
        buffer.toArray();
    };

    /// Decodes an SLEB128-encoded `Int` from a byte iterator.
    /// Traps if end of buffer is reached before value is completely decoded.
    public func fromSLEB128(bytes : Bytes) : Int {
        let buffer = ListBuffer<Nat8>();
        for (byte in bytes) { buffer.add(byte) };
        Buffer.readSLEB128_int(buffer);
    };

    public module Buffer {

        public func addBytes(buffer : BufferLike<Nat8>, iter : Iter.Iter<Nat8>) {
            for (elem in iter) { buffer.add(elem) };
        };

        public module LittleEndian {
            // Rename existing write methods to add methods (add to end of buffer)
            public func addNat8(buffer : BufferLike<Nat8>, n : Nat8) {
                buffer.add(n);
            };

            public func addNat16(buffer : BufferLike<Nat8>, n : Nat16) {
                let bytes = Prim.explodeNat16(n);
                buffer.add(bytes.1); // LSB
                buffer.add(bytes.0); // MSB
            };

            public func addNat32(buffer : BufferLike<Nat8>, n : Nat32) {
                let bytes = Prim.explodeNat32(n);
                buffer.add(bytes.3); // LSB
                buffer.add(bytes.2);
                buffer.add(bytes.1);
                buffer.add(bytes.0); // MSB
            };

            public func addNat64(buffer : BufferLike<Nat8>, n : Nat64) {
                let bytes = Prim.explodeNat64(n);
                buffer.add(bytes.7); // LSB
                buffer.add(bytes.6);
                buffer.add(bytes.5);
                buffer.add(bytes.4);
                buffer.add(bytes.3);
                buffer.add(bytes.2);
                buffer.add(bytes.1);
                buffer.add(bytes.0); // MSB
            };

            public func addInt8(buffer : BufferLike<Nat8>, i : Int8) {
                buffer.add(Int8.toNat8(i));
            };

            public func addInt16(buffer : BufferLike<Nat8>, i : Int16) {
                let nat16 = Int16.toNat16(i);
                addNat16(buffer, nat16);
            };

            public func addInt32(buffer : BufferLike<Nat8>, i : Int32) {
                let nat32 = Int32.toNat32(i);
                addNat32(buffer, nat32);
            };

            public func addInt64(buffer : BufferLike<Nat8>, i : Int64) {
                let nat64 = Int64.toNat64(i);
                addNat64(buffer, nat64);
            };

            public func addFloat(buffer : BufferLike<Nat8>, f : Float) {
                let fx = FloatX.fromFloat(f, #f64);
                FloatX.toBytesBuffer({ write = buffer.add }, fx, #lsb);
            };

            // Add new write methods (write at specific offset)
            public func writeNat8(buffer : BufferLike<Nat8>, offset : Nat, n : Nat8) {
                buffer.put(offset, n);
            };

            public func writeNat16(buffer : BufferLike<Nat8>, offset : Nat, n : Nat16) {
                let bytes = Prim.explodeNat16(n);
                buffer.put(offset, bytes.1); // LSB
                buffer.put(offset + 1, bytes.0); // MSB
            };

            public func writeNat32(buffer : BufferLike<Nat8>, offset : Nat, n : Nat32) {
                let bytes = Prim.explodeNat32(n);
                buffer.put(offset, bytes.3); // LSB
                buffer.put(offset + 1, bytes.2);
                buffer.put(offset + 2, bytes.1);
                buffer.put(offset + 3, bytes.0); // MSB
            };

            public func writeNat64(buffer : BufferLike<Nat8>, offset : Nat, n : Nat64) {
                let bytes = Prim.explodeNat64(n);
                buffer.put(offset, bytes.7); // LSB
                buffer.put(offset + 1, bytes.6);
                buffer.put(offset + 2, bytes.5);
                buffer.put(offset + 3, bytes.4);
                buffer.put(offset + 4, bytes.3);
                buffer.put(offset + 5, bytes.2);
                buffer.put(offset + 6, bytes.1);
                buffer.put(offset + 7, bytes.0); // MSB
            };

            public func writeInt8(buffer : BufferLike<Nat8>, offset : Nat, i : Int8) {
                buffer.put(offset, Int8.toNat8(i));
            };

            public func writeInt16(buffer : BufferLike<Nat8>, offset : Nat, i : Int16) {
                let nat16 = Int16.toNat16(i);
                writeNat16(buffer, offset, nat16);
            };

            public func writeInt32(buffer : BufferLike<Nat8>, offset : Nat, i : Int32) {
                let nat32 = Int32.toNat32(i);
                writeNat32(buffer, offset, nat32);
            };

            public func writeInt64(buffer : BufferLike<Nat8>, offset : Nat, i : Int64) {
                let nat64 = Int64.toNat64(i);
                writeNat64(buffer, offset, nat64);
            };

            public func writeFloat(buffer : BufferLike<Nat8>, offset : Nat, f : Float) {
                let fx = FloatX.fromFloat(f, #f64);
                let tempBuffer = ListBuffer<Nat8>();
                FloatX.toBytesBuffer({ write = tempBuffer.add }, fx, #lsb);

                // Copy from temp buffer to target buffer at offset
                for (i in Nat.range(0, 8)) {
                    buffer.put(offset + i, tempBuffer.get(i));
                };
            };

            public func readNat8(buffer : BufferLike<Nat8>, offset : Nat) : Nat8 {
                buffer.get(offset);
            };

            public func readNat16(buffer : BufferLike<Nat8>, offset : Nat) : Nat16 {
                let low = buffer.get(offset);
                let high = buffer.get(offset + 1);
                Nat16.fromNat8(low) | Nat16.fromNat8(high) << 8;
            };

            public func readNat32(buffer : BufferLike<Nat8>, offset : Nat) : Nat32 {
                let b1 = buffer.get(offset);
                let b2 = buffer.get(offset + 1);
                let b3 = buffer.get(offset + 2);
                let b4 = buffer.get(offset + 3);

                Nat32.fromNat(Nat8.toNat(b1)) | Nat32.fromNat(Nat8.toNat(b2)) << 8 | Nat32.fromNat(Nat8.toNat(b3)) << 16 | Nat32.fromNat(Nat8.toNat(b4)) << 24;
            };

            public func readNat64(buffer : BufferLike<Nat8>, offset : Nat) : Nat64 {
                let b1 = buffer.get(offset);
                let b2 = buffer.get(offset + 1);
                let b3 = buffer.get(offset + 2);
                let b4 = buffer.get(offset + 3);
                let b5 = buffer.get(offset + 4);
                let b6 = buffer.get(offset + 5);
                let b7 = buffer.get(offset + 6);
                let b8 = buffer.get(offset + 7);

                Nat64.fromNat(Nat8.toNat(b1)) | Nat64.fromNat(Nat8.toNat(b2)) << 8 | Nat64.fromNat(Nat8.toNat(b3)) << 16 | Nat64.fromNat(Nat8.toNat(b4)) << 24 | Nat64.fromNat(Nat8.toNat(b5)) << 32 | Nat64.fromNat(Nat8.toNat(b6)) << 40 | Nat64.fromNat(Nat8.toNat(b7)) << 48 | Nat64.fromNat(Nat8.toNat(b8)) << 56;
            };

            public func readInt8(buffer : BufferLike<Nat8>, offset : Nat) : Int8 {
                Int8.fromNat8(buffer.get(offset));
            };

            public func readInt16(buffer : BufferLike<Nat8>, offset : Nat) : Int16 {
                let nat16 = readNat16(buffer, offset);
                Int16.fromNat16(nat16);
            };

            public func readInt32(buffer : BufferLike<Nat8>, offset : Nat) : Int32 {
                let nat32 = readNat32(buffer, offset);
                Int32.fromNat32(nat32);
            };

            public func readInt64(buffer : BufferLike<Nat8>, offset : Nat) : Int64 {
                let nat64 = readNat64(buffer, offset);
                Int64.fromNat64(nat64);
            };

        };

        public module BigEndian {
            // Rename existing write methods to add methods (add to end of buffer)
            public func addNat8(buffer : BufferLike<Nat8>, n : Nat8) {
                buffer.add(n);
            };

            public func addNat16(buffer : BufferLike<Nat8>, n : Nat16) {
                let bytes = Prim.explodeNat16(n);
                buffer.add(bytes.0); // MSB
                buffer.add(bytes.1); // LSB
            };

            public func addNat32(buffer : BufferLike<Nat8>, n : Nat32) {
                let bytes = Prim.explodeNat32(n);
                buffer.add(bytes.0); // MSB
                buffer.add(bytes.1);
                buffer.add(bytes.2);
                buffer.add(bytes.3); // LSB
            };

            public func addNat64(buffer : BufferLike<Nat8>, n : Nat64) {
                let bytes = Prim.explodeNat64(n);
                buffer.add(bytes.0); // MSB
                buffer.add(bytes.1);
                buffer.add(bytes.2);
                buffer.add(bytes.3);
                buffer.add(bytes.4);
                buffer.add(bytes.5);
                buffer.add(bytes.6);
                buffer.add(bytes.7); // LSB
            };

            public func addInt8(buffer : BufferLike<Nat8>, i : Int8) {
                buffer.add(Int8.toNat8(i));
            };

            public func addInt16(buffer : BufferLike<Nat8>, i : Int16) {
                let nat16 = Int16.toNat16(i);
                addNat16(buffer, nat16);
            };

            public func addInt32(buffer : BufferLike<Nat8>, i : Int32) {
                let nat32 = Int32.toNat32(i);
                addNat32(buffer, nat32);
            };

            public func addInt64(buffer : BufferLike<Nat8>, i : Int64) {
                let nat64 = Int64.toNat64(i);
                addNat64(buffer, nat64);
            };

            public func addFloat(buffer : BufferLike<Nat8>, f : Float) {
                let fx = FloatX.fromFloat(f, #f64);
                FloatX.toBytesBuffer({ write = buffer.add }, fx, #msb);
            };

            // Add new write methods (write at specific offset)
            public func writeNat8(buffer : BufferLike<Nat8>, offset : Nat, n : Nat8) {
                buffer.put(offset, n);
            };

            public func writeNat16(buffer : BufferLike<Nat8>, offset : Nat, n : Nat16) {
                let bytes = Prim.explodeNat16(n);
                buffer.put(offset, bytes.0); // MSB
                buffer.put(offset + 1, bytes.1); // LSB
            };

            public func writeNat32(buffer : BufferLike<Nat8>, offset : Nat, n : Nat32) {
                let bytes = Prim.explodeNat32(n);
                buffer.put(offset, bytes.0); // MSB
                buffer.put(offset + 1, bytes.1);
                buffer.put(offset + 2, bytes.2);
                buffer.put(offset + 3, bytes.3); // LSB
            };

            public func writeNat64(buffer : BufferLike<Nat8>, offset : Nat, n : Nat64) {
                let bytes = Prim.explodeNat64(n);
                buffer.put(offset, bytes.0); // MSB
                buffer.put(offset + 1, bytes.1);
                buffer.put(offset + 2, bytes.2);
                buffer.put(offset + 3, bytes.3);
                buffer.put(offset + 4, bytes.4);
                buffer.put(offset + 5, bytes.5);
                buffer.put(offset + 6, bytes.6);
                buffer.put(offset + 7, bytes.7); // LSB
            };

            public func writeInt8(buffer : BufferLike<Nat8>, offset : Nat, i : Int8) {
                buffer.put(offset, Int8.toNat8(i));
            };

            public func writeInt16(buffer : BufferLike<Nat8>, offset : Nat, i : Int16) {
                let nat16 = Int16.toNat16(i);
                writeNat16(buffer, offset, nat16);
            };

            public func writeInt32(buffer : BufferLike<Nat8>, offset : Nat, i : Int32) {
                let nat32 = Int32.toNat32(i);
                writeNat32(buffer, offset, nat32);
            };

            public func writeInt64(buffer : BufferLike<Nat8>, offset : Nat, i : Int64) {
                let nat64 = Int64.toNat64(i);
                writeNat64(buffer, offset, nat64);
            };

            public func writeFloat(buffer : BufferLike<Nat8>, offset : Nat, f : Float) {
                let fx = FloatX.fromFloat(f, #f64);
                let tempBuffer = ListBuffer<Nat8>();
                FloatX.toBytesBuffer({ write = tempBuffer.add }, fx, #msb);

                // Copy from temp buffer to target buffer at offset
                for (i in Nat.range(0, 8)) {
                    buffer.put(offset + i, tempBuffer.get(i));
                };
            };

            public func readNat8(buffer : BufferLike<Nat8>, offset : Nat) : Nat8 {
                buffer.get(offset);
            };

            public func readNat16(buffer : BufferLike<Nat8>, offset : Nat) : Nat16 {
                let high = buffer.get(offset);
                let low = buffer.get(offset + 1);
                Nat16.fromNat8(high) << 8 | Nat16.fromNat8(low);
            };

            public func readNat32(buffer : BufferLike<Nat8>, offset : Nat) : Nat32 {
                let b1 = buffer.get(offset);
                let b2 = buffer.get(offset + 1);
                let b3 = buffer.get(offset + 2);
                let b4 = buffer.get(offset + 3);

                Nat32.fromNat(Nat8.toNat(b1)) << 24 | Nat32.fromNat(Nat8.toNat(b2)) << 16 | Nat32.fromNat(Nat8.toNat(b3)) << 8 | Nat32.fromNat(Nat8.toNat(b4));
            };

            public func readNat64(buffer : BufferLike<Nat8>, offset : Nat) : Nat64 {
                let b1 = buffer.get(offset);
                let b2 = buffer.get(offset + 1);
                let b3 = buffer.get(offset + 2);
                let b4 = buffer.get(offset + 3);
                let b5 = buffer.get(offset + 4);
                let b6 = buffer.get(offset + 5);
                let b7 = buffer.get(offset + 6);
                let b8 = buffer.get(offset + 7);

                Nat64.fromNat(Nat8.toNat(b1)) << 56 | Nat64.fromNat(Nat8.toNat(b2)) << 48 | Nat64.fromNat(Nat8.toNat(b3)) << 40 | Nat64.fromNat(Nat8.toNat(b4)) << 32 | Nat64.fromNat(Nat8.toNat(b5)) << 24 | Nat64.fromNat(Nat8.toNat(b6)) << 16 | Nat64.fromNat(Nat8.toNat(b7)) << 8 | Nat64.fromNat(Nat8.toNat(b8));
            };

            public func readInt8(buffer : BufferLike<Nat8>, offset : Nat) : Int8 {
                Int8.fromNat8(buffer.get(offset));
            };

            public func readInt16(buffer : BufferLike<Nat8>, offset : Nat) : Int16 {
                let nat16 = readNat16(buffer, offset);
                Int16.fromNat16(nat16);
            };

            public func readInt32(buffer : BufferLike<Nat8>, offset : Nat) : Int32 {
                let nat32 = readNat32(buffer, offset);
                Int32.fromNat32(nat32);
            };

            public func readInt64(buffer : BufferLike<Nat8>, offset : Nat) : Int64 {
                let nat64 = readNat64(buffer, offset);
                Int64.fromNat64(nat64);
            };

        };

        public module Sorted {
            // Buffer operations using sortable encodings

            public func addNat8(buffer : BufferLike<Nat8>, n : Nat8) {
                let bytes = ByteUtils.Sorted.fromNat8(n);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            public func addNat16(buffer : BufferLike<Nat8>, n : Nat16) {
                let bytes = ByteUtils.Sorted.fromNat16(n);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            public func addNat32(buffer : BufferLike<Nat8>, n : Nat32) {
                let bytes = ByteUtils.Sorted.fromNat32(n);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            public func addNat64(buffer : BufferLike<Nat8>, n : Nat64) {
                let bytes = ByteUtils.Sorted.fromNat64(n);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            public func addInt8(buffer : BufferLike<Nat8>, i : Int8) {
                let bytes = ByteUtils.Sorted.fromInt8(i);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            public func addInt16(buffer : BufferLike<Nat8>, i : Int16) {
                let bytes = ByteUtils.Sorted.fromInt16(i);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            public func addInt32(buffer : BufferLike<Nat8>, i : Int32) {
                let bytes = ByteUtils.Sorted.fromInt32(i);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            public func addInt64(buffer : BufferLike<Nat8>, i : Int64) {
                let bytes = ByteUtils.Sorted.fromInt64(i);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            public func addFloat(buffer : BufferLike<Nat8>, f : Float) {
                let bytes = ByteUtils.Sorted.fromFloat(f);
                for (byte in bytes.vals()) { buffer.add(byte) };
            };

            // Write functions (at specific offset)
            public func writeNat8(buffer : BufferLike<Nat8>, offset : Nat, n : Nat8) {
                let bytes = ByteUtils.Sorted.fromNat8(n);
                for (i in Nat.range(0, bytes.size())) {
                    buffer.put(offset + i, bytes[i]);
                };
            };

            public func writeNat16(buffer : BufferLike<Nat8>, offset : Nat, n : Nat16) {
                let bytes = ByteUtils.Sorted.fromNat16(n);
                for (i in Nat.range(0, bytes.size())) {
                    buffer.put(offset + i, bytes[i]);
                };
            };

            public func writeNat32(buffer : BufferLike<Nat8>, offset : Nat, n : Nat32) {
                let bytes = ByteUtils.Sorted.fromNat32(n);
                for (i in Nat.range(0, bytes.size())) {
                    buffer.put(offset + i, bytes[i]);
                };
            };

            public func writeNat64(buffer : BufferLike<Nat8>, offset : Nat, n : Nat64) {
                let bytes = ByteUtils.Sorted.fromNat64(n);
                for (i in Nat.range(0, bytes.size())) {
                    buffer.put(offset + i, bytes[i]);
                };
            };

            public func writeInt8(buffer : BufferLike<Nat8>, offset : Nat, i : Int8) {
                let bytes = ByteUtils.Sorted.fromInt8(i);
                for (j in Nat.range(0, bytes.size())) {
                    buffer.put(offset + j, bytes[j]);
                };
            };

            public func writeInt16(buffer : BufferLike<Nat8>, offset : Nat, i : Int16) {
                let bytes = ByteUtils.Sorted.fromInt16(i);
                for (j in Nat.range(0, bytes.size())) {
                    buffer.put(offset + j, bytes[j]);
                };
            };

            public func writeInt32(buffer : BufferLike<Nat8>, offset : Nat, i : Int32) {
                let bytes = ByteUtils.Sorted.fromInt32(i);
                for (j in Nat.range(0, bytes.size())) {
                    buffer.put(offset + j, bytes[j]);
                };
            };

            public func writeInt64(buffer : BufferLike<Nat8>, offset : Nat, i : Int64) {
                let bytes = ByteUtils.Sorted.fromInt64(i);
                for (j in Nat.range(0, bytes.size())) {
                    buffer.put(offset + j, bytes[j]);
                };
            };

            public func writeFloat(buffer : BufferLike<Nat8>, offset : Nat, f : Float) {
                let bytes = ByteUtils.Sorted.fromFloat(f);
                for (i in Nat.range(0, bytes.size())) {
                    buffer.put(offset + i, bytes[i]);
                };
            };

            // Read functions
            public func readNat8(buffer : BufferLike<Nat8>, offset : Nat) : Nat8 {
                let bytes = [buffer.get(offset)];
                ByteUtils.Sorted.toNat8(bytes.vals());
            };

            public func readNat16(buffer : BufferLike<Nat8>, offset : Nat) : Nat16 {
                let bytes = [buffer.get(offset), buffer.get(offset + 1)];
                ByteUtils.Sorted.toNat16(bytes.vals());
            };

            public func readNat32(buffer : BufferLike<Nat8>, offset : Nat) : Nat32 {
                let bytes = [buffer.get(offset), buffer.get(offset + 1), buffer.get(offset + 2), buffer.get(offset + 3)];
                ByteUtils.Sorted.toNat32(bytes.vals());
            };

            public func readNat64(buffer : BufferLike<Nat8>, offset : Nat) : Nat64 {
                let bytes = [buffer.get(offset), buffer.get(offset + 1), buffer.get(offset + 2), buffer.get(offset + 3), buffer.get(offset + 4), buffer.get(offset + 5), buffer.get(offset + 6), buffer.get(offset + 7)];
                ByteUtils.Sorted.toNat64(bytes.vals());
            };

            public func readInt8(buffer : BufferLike<Nat8>, offset : Nat) : Int8 {
                let bytes = [buffer.get(offset)];
                ByteUtils.Sorted.toInt8(bytes.vals());
            };

            public func readInt16(buffer : BufferLike<Nat8>, offset : Nat) : Int16 {
                let bytes = [buffer.get(offset), buffer.get(offset + 1)];
                ByteUtils.Sorted.toInt16(bytes.vals());
            };

            public func readInt32(buffer : BufferLike<Nat8>, offset : Nat) : Int32 {
                let bytes = [buffer.get(offset), buffer.get(offset + 1), buffer.get(offset + 2), buffer.get(offset + 3)];
                ByteUtils.Sorted.toInt32(bytes.vals());
            };

            public func readInt64(buffer : BufferLike<Nat8>, offset : Nat) : Int64 {
                let bytes = [buffer.get(offset), buffer.get(offset + 1), buffer.get(offset + 2), buffer.get(offset + 3), buffer.get(offset + 4), buffer.get(offset + 5), buffer.get(offset + 6), buffer.get(offset + 7)];
                ByteUtils.Sorted.toInt64(bytes.vals());
            };

            public func readFloat(buffer : BufferLike<Nat8>, offset : Nat) : Float {
                let bytes = [buffer.get(offset), buffer.get(offset + 1), buffer.get(offset + 2), buffer.get(offset + 3), buffer.get(offset + 4), buffer.get(offset + 5), buffer.get(offset + 6), buffer.get(offset + 7)];
                ByteUtils.Sorted.toFloat(bytes.vals());
            };
        };

        public let LE = LittleEndian;
        public let BE = BigEndian;

        // Encodings that have a consistent endianness

        // https://en.wikipedia.org/wiki/LEB128
        // limited to 64-bit unsigned integers
        // more performant than the general unsigned_leb128
        /// Add ULEB128 encoded number to the end of a buffer
        public func addLEB128_64(buffer : BufferLike<Nat8>, n : Nat64) {
            var value = n;
            while (value >= 0x80) {
                buffer.add(Nat8.fromNat(Nat64.toNat(value & 0x7F)) | 0x80);
                value >>= 7;
            };
            buffer.add(Nat8.fromNat(Nat64.toNat(value)));

        };

        /// Write ULEB128 encoded value at a specific offset.
        /// Traps if the buffer is smaller than the offset and number of encoded bytes.
        public func writeLEB128_64(buffer : BufferLike<Nat8>, offset : Nat, n : Nat64) {
            var n64 : Nat64 = n;
            var index = offset;

            loop {
                var byte = n64 & 0x7F |> Nat64.toNat(_) |> Nat8.fromNat(_);
                n64 >>= 7;

                if (n64 > 0) byte := (byte | 0x80);
                buffer.put(index, byte);
                index += 1;

            } while (n64 > 0);

        };

        /// Add ULEB128 encoded Nat to the end of the buffer.
        public func addLEB128_nat(buffer : BufferLike<Nat8>, n : Nat) {
            var value = n;
            while (value >= 0x80) {
                buffer.add(Nat8.fromNat(value % 0x80) + 0x80);
                value /= 0x80;
            };
            buffer.add(Nat8.fromNat(value));

        };

        /// Write ULEB128 encoded value at a specific offset.
        /// Traps if the buffer is smaller than the offset and number of encoded bytes.
        public func writeLEB128_nat(buffer : BufferLike<Nat8>, offset : Nat, n : Nat) {
            var value = n;
            var index = offset;

            while (value >= 0x80) {
                buffer.put(index, Nat8.fromNat(value % 0x80) + 0x80);
                index += 1;
                value /= 0x80;
            };
            buffer.put(index, Nat8.fromNat(value));

        };

        // https://en.wikipedia.org/wiki/LEB128
        // limited to 64-bit signed integers
        // more performant than the general signed_leb128
        /// Add SLEB128 encoded value to the end of a buffer.
        public func addSLEB128_64(buffer : BufferLike<Nat8>, _n : Int64) {
            let n = Int64.toInt(_n);
            let is_negative = n < 0;

            // Convert to correct absolute value representation first
            var value : Nat64 = if (is_negative) {
                // For negative numbers in two's complement: bitwise NOT of abs(n)-1
                Nat64.fromNat(Int.abs(n) - 1);
            } else {
                Nat64.fromNat(Int.abs(n));
            };

            var more = true;

            while (more) {
                // Get lowest 7 bits
                var byte : Nat8 = Nat8.fromNat(Nat64.toNat(value & 0x7F));

                // Shift for next iteration
                value >>= 7;

                // Determine if we need more bytes
                if (
                    (value == 0 and (byte & 0x40) == 0) or
                    (is_negative and value == Nat64.fromNat(Int.abs(Int64.toInt(Int64.maxValue))) and (byte & 0x40) != 0)
                ) {
                    more := false;
                } else {
                    byte |= 0x80; // Set continuation bit
                };

                // For negative numbers, invert bits (apply two's complement)
                if (is_negative) {
                    byte := byte ^ 0x7F;
                };

                buffer.add(byte);
            };
        };

        /// Write SLEB128 encoded value at a specific offset.
        /// Traps if the buffer is smaller than the offset and number of encoded bytes.
        public func writeSLEB128_64(buffer : BufferLike<Nat8>, offset : Nat, _n : Int64) {
            let n = Int64.toInt(_n);
            let is_negative = n < 0;
            var index = offset;

            // Convert to correct absolute value representation first
            var value : Nat64 = if (is_negative) {
                // For negative numbers in two's complement: bitwise NOT of abs(n)-1
                Nat64.fromNat(Int.abs(n) - 1);
            } else {
                Nat64.fromNat(Int.abs(n));
            };

            var more = true;

            while (more) {
                // Get lowest 7 bits
                var byte : Nat8 = Nat8.fromNat(Nat64.toNat(value & 0x7F));

                // Shift for next iteration
                value >>= 7;

                // Determine if we need more bytes
                if (
                    (value == 0 and (byte & 0x40) == 0) or
                    (is_negative and value == Nat64.fromNat(Int.abs(Int64.toInt(Int64.maxValue))) and (byte & 0x40) != 0)
                ) {
                    more := false;
                } else {
                    byte |= 0x80; // Set continuation bit
                };

                // For negative numbers, invert bits (apply two's complement)
                if (is_negative) {
                    byte := byte ^ 0x7F;
                };

                buffer.put(index, byte);
                index += 1;
            };

        };

        /// Add SLEB128 encoded value to the end of a buffer.
        public func addSLEB128_int(buffer : BufferLike<Nat8>, n : Int) {
            var value = n;
            let is_negative = value < 0;

            // Convert to correct absolute value representation first
            var more = true;

            while (more) {
                // Get lowest 7 bits
                var byte : Nat8 = Nat8.fromIntWrap(value) & 0x7F;

                // Shift for next iteration
                if (is_negative) {
                    value := (value - 127) / 128; // -127 to round down instead of towards 0
                } else {
                    value /= 128;
                };

                // Determine if we need more bytes
                if (
                    (value == 0 and (byte & 0x40) == 0) or
                    (value == -1 and (byte & 0x40) != 0)
                ) {
                    more := false;
                } else {
                    byte |= 0x80; // Set continuation bit
                };

                buffer.add(byte);
            };
        };

        /// Write SLEB128 encoded value at a specific offset.
        /// Traps if the buffer is smaller than the offset and number of encoded bytes.
        public func writeSLEB128_int(buffer : BufferLike<Nat8>, offset : Nat, n : Int) {
            var value = n;
            let is_negative = value < 0;
            var index = offset;

            // Convert to correct absolute value representation first
            var more = true;

            while (more) {
                // Get lowest 7 bits
                var byte : Nat8 = Nat8.fromIntWrap(value) & 0x7F;

                // Shift for next iteration
                if (is_negative) {
                    value := (value - 127) / 128; // -127 to round down instead of towards 0
                } else {
                    value /= 128;
                };

                // Determine if we need more bytes
                if (
                    (value == 0 and (byte & 0x40) == 0) or
                    (value == -1 and (byte & 0x40) != 0)
                ) {
                    more := false;
                } else {
                    byte |= 0x80; // Set continuation bit
                };

                buffer.put(index, byte);
                index += 1;
            };
        };

        // https://en.wikipedia.org/wiki/LEB128
        /// Read unsigned LEB128 value from buffer.
        /// Traps if end of buffer is reached before value is completely decoded.
        public func readLEB128_64(buffer : BufferLike<Nat8>) : Nat64 {
            var n64 : Nat64 = 0;
            var shift : Nat64 = 0;
            var i = 0;

            label decoding_leb loop {
                let byte = buffer.get(i);
                i += 1;

                n64 |= (Nat64.fromNat(Nat8.toNat(byte & 0x7f)) << shift);

                if (byte & 0x80 == 0) break decoding_leb;
                shift += 7;

            };

            n64;
        };

        /// Read unsigned LEB128 value from buffer.
        /// Traps if end of buffer is reached before value is completely decoded.
        public func readLEB128_nat(buffer : BufferLike<Nat8>) : Nat {
            var n : Nat = 0;
            var shift : Nat = 1;
            var i = 0;

            label decoding_leb loop {
                let byte = buffer.get(i);
                i += 1;

                n += (Nat8.toNat(byte & 0x7f)) * shift;

                if (byte & 0x80 == 0) break decoding_leb;
                shift *= 128;

            };

            n;
        };

        /// Read signed LEB128 value from buffer.
        /// Traps if end of buffer is reached before value is completely decoded.
        public func readSLEB128_64(buffer : BufferLike<Nat8>) : Int64 {
            var result : Nat64 = 0;
            var shift : Nat64 = 0;
            var byte : Nat8 = 0;
            var i = 0;

            label analyzing loop {
                byte := buffer.get(i);
                i += 1;

                // Add this byte's 7 bits to the result
                result |= Nat64.fromNat(Nat8.toNat(byte & 0x7F)) << shift;
                shift += 7;

                // If continuation bit is not set, we're done reading bytes
                if ((byte & 0x80) == 0) {
                    break analyzing;
                };
            };

            // Sign extend if this is a negative number
            if (byte & 0x40 != 0 and shift < 64) {
                // Fill the rest with 1s (sign extension)
                result |= ^((Nat64.fromNat(1) << shift) - 1);
            };

            Int64.fromNat64(result);
        };

        /// Read signed LEB128 value from buffer.
        /// Traps if end of buffer is reached before value is completely decoded.
        public func readSLEB128_int(buffer : BufferLike<Nat8>) : Int {
            var result : Int = 0;
            var shift : Int = 1;
            var byte : Nat8 = 0;
            var i = 0;

            label analyzing loop {
                byte := buffer.get(i);
                i += 1;

                // Add this byte's 7 bits to the result
                result += Nat8.toNat(byte & 0x7F) * shift;
                shift *= 128;

                // If continuation bit is not set, we're done reading bytes
                if ((byte & 0x80) == 0) {
                    break analyzing;
                };
            };

            // Sign extend if this is a negative number
            if (byte & 0x40 != 0) {
                // Fill the rest with 1s (sign extension)
                result -= shift;
            };

            result;
        };

    };
};
