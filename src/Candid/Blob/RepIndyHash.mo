import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import Int8 "mo:base/Int8";
import Int32 "mo:base/Int32";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat16 "mo:base/Nat16";
import Int64 "mo:base/Int64";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Order "mo:base/Order";
import Option "mo:base/Option";
import Func "mo:base/Func";
import Char "mo:base/Char";
import Int16 "mo:base/Int16";
import Itertools "mo:itertools/Iter";

import T "../Types";
import Utils "../../Utils";
import Sha256 "mo:sha2/Sha256";

module {
    type Buffer<A> = Buffer.Buffer<A>;

    let { ReusableBuffer; unsigned_leb128; signed_leb128_64 } = Utils;

    public func hash(candid_value : T.Candid) : Blob {
        let buffer = ReusableBuffer<Nat8>(100);
        let sha256 = Sha256.Digest(#sha256);

        candid_hash(buffer, sha256, candid_value);
    };

    func candid_hash(
        buffer : Utils.ReusableBuffer<Nat8>,
        sha256 : Sha256.Digest,
        candid_value : T.Candid,
    ) : Blob {
        switch (candid_value) {
            case (#Int(n)) signed_leb128_64(buffer, n);
            case (#Int8(i8)) {
                buffer.add(Int8.toNat8(i8));
            };
            case (#Int16(i16)) {
                let n16 = Int16.toNat16(i16);
                buffer.add((n16 & 0xFF) |> Nat16.toNat8(_));
                buffer.add((n16 >> 8) |> Nat16.toNat8(_));
            };
            case (#Int32(i32)) {
                let n = Int32.toNat32(i32);

                buffer.add((n & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                buffer.add(((n >> 8) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                buffer.add(((n >> 16) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                buffer.add((n >> 24) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
            };
            case (#Int64(i64)) {
                let n = Int64.toNat64(i64);

                buffer.add((n & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 8) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 16) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 24) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 32) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 40) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 48) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add((n >> 56) |> Nat64.toNat(_) |> Nat8.fromNat(_));
            };

            case (#Nat(n)) unsigned_leb128(buffer, n);

            case (#Nat8(n)) {
                buffer.add(n);
            };
            case (#Nat16(n)) {
                buffer.add((n & 0xFF) |> Nat16.toNat8(_));
                buffer.add((n >> 8) |> Nat16.toNat8(_));
            };
            case (#Nat32(n)) {
                buffer.add((n & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                buffer.add(((n >> 8) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                buffer.add(((n >> 16) & 0xFF) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
                buffer.add((n >> 24) |> Nat32.toNat16(_) |> Nat16.toNat8(_));
            };
            case (#Nat64(n)) {
                buffer.add((n & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 8) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 16) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 24) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 32) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 40) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add(((n >> 48) & 0xFF) |> Nat64.toNat(_) |> Nat8.fromNat(_));
                buffer.add((n >> 56) |> Nat64.toNat(_) |> Nat8.fromNat(_));

            };

            case (#Float(f64)) {
                // let floatX : FloatX.FloatX = FloatX.fromFloat(f64, #f64);
                // FloatX.encode(buffer, floatX, #lsb);
            };
            case (#Bool(b)) {
                buffer.add(if (b) (1) else (0));
            };
            case (#Null) {};

            case (#Text(t)) {

                let utf8_bytes = Blob.toArray(Text.encodeUtf8(t));

                var i = 0;
                while (i < utf8_bytes.size()) {
                    buffer.add(utf8_bytes[i]);
                    i += 1;
                };

            };
            case (#Blob(b)) {
                sha256.writeBlob(b);
            };
            case (#Principal(p)) {

                let bytes = Blob.toArray(Principal.toBlob(p));

                var i = 0;
                while (i < bytes.size()) {
                    buffer.add(bytes[i]);
                    i += 1;
                };
            };

            case (#Array(values)) {

                let hashes = Array.tabulate(
                    values.size(),
                    func(i : Nat) : Blob {
                        candid_hash(buffer, sha256, values[i]);
                    },
                );

                for (hash in hashes.vals()) {
                    let hash_bytes = Blob.toArray(hash);
                    for (byte in hash_bytes.vals()) {
                        buffer.add(byte);
                    };
                };
            };
            case (#Record(records) or #Map(records)) {
                let hashes = Buffer.Buffer<Blob>(8);
                label record_hashing for ((key, value) in records.vals()) {
                    let key_hash = candid_hash(buffer, sha256, #Text(key));

                    let unwrapped_value = switch (value) {
                        case (#Null) continue record_hashing;
                        case (#Option(inner_type)) inner_type;
                        case (value) value;
                    };

                    let value_hash = candid_hash(buffer, sha256, unwrapped_value);

                    let concatenated = Blob.fromArray(
                        Array.append(
                            Blob.toArray(key_hash),
                            Blob.toArray(value_hash),
                        )
                    );

                    hashes.add(concatenated);
                };

                hashes.sort(Blob.compare);

                for (hash in hashes.vals()) {
                    let hash_bytes = Blob.toArray(hash);
                    for (byte in hash_bytes.vals()) {
                        buffer.add(byte);
                    };
                };

            };
            case (candid) Debug.trap("oops: " # debug_show (candid));
        };

        sha256.writeIter(buffer.vals());
        buffer.clear();

        let resulting_hash = sha256.sum();
        sha256.reset();

        resulting_hash;

    };
};
