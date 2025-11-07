import Array "mo:base@0.16.0/Array";
import Blob "mo:base@0.16.0/Blob";
import Buffer "mo:base@0.16.0/Buffer";
import Debug "mo:base@0.16.0/Debug";
import Nat64 "mo:base@0.16.0/Nat64";
import Int8 "mo:base@0.16.0/Int8";
import Int32 "mo:base@0.16.0/Int32";
import Nat8 "mo:base@0.16.0/Nat8";
import Nat32 "mo:base@0.16.0/Nat32";
import Nat16 "mo:base@0.16.0/Nat16";
import Int64 "mo:base@0.16.0/Int64";
import Nat "mo:base@0.16.0/Nat";
import Principal "mo:base@0.16.0/Principal";
import Text "mo:base@0.16.0/Text";
import Int16 "mo:base@0.16.0/Int16";

import T "../Types";
import Utils "../../Utils";
import Sha256 "mo:sha2@0.1.6/Sha256";

import ByteUtils "mo:byte-utils@0.1.2";

module {
    type Buffer<A> = Buffer.Buffer<A>;

    let { ReusableBuffer; unsigned_leb128; signed_leb128_64 } = Utils;

    public func hash(candid_value : T.Candid) : Blob {
        // let buffer = ReusableBuffer<Nat8>(100);
        let buffer = Buffer.Buffer<Nat8>(100);
        let sha256 = Sha256.Digest(#sha256);

        candid_hash(buffer, sha256, candid_value);
    };

    func candid_hash(
        buffer : Buffer.Buffer<Nat8>,
        sha256 : Sha256.Digest,
        candid_value : T.Candid,
    ) : Blob {
        switch (candid_value) {
            case (#Int(n)) signed_leb128_64(buffer, n);
            case (#Int8(i8)) {
                ByteUtils.Buffer.LE.addInt8(buffer, i8);
            };
            case (#Int16(i16)) {
                ByteUtils.Buffer.LE.addInt16(buffer, i16);
            };
            case (#Int32(i32)) {
                ByteUtils.Buffer.LE.addInt32(buffer, i32);
            };
            case (#Int64(i64)) {
                ByteUtils.Buffer.LE.addInt64(buffer, i64);
            };

            case (#Nat(n)) unsigned_leb128(buffer, n);

            case (#Nat8(n)) {
                buffer.add(n);
            };
            case (#Nat16(n)) {
                ByteUtils.Buffer.LE.addNat16(buffer, n);
            };
            case (#Nat32(n)) {
                ByteUtils.Buffer.LE.addNat32(buffer, n);
            };
            case (#Nat64(n)) {
                ByteUtils.Buffer.LE.addNat64(buffer, n);
            };

            case (#Float(f64)) {
                ByteUtils.Buffer.LE.addFloat(buffer, f64);
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
        sha256.reset(); // !important to reset the sha256 instance for future use

        resulting_hash;

    };
};
