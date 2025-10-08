// @testmode wasi
import Blob "mo:base@0.14.14/Blob";
import Debug "mo:base@0.14.14/Debug";
import Iter "mo:base@0.14.14/Iter";
import Nat "mo:base@0.14.14/Nat";
import Principal "mo:base@0.14.14/Principal";
import Result "mo:base@0.14.14/Result";
import Option "mo:base@0.14.14/Option";

import { test; suite } "mo:test";

import Serde "../src";
import Candid "../src/Candid";
import Encoder "../src/Candid/Blob/Encoder";

module {
    type Candid = Candid.Candid;

    public func encode_with_types(types : [Candid.CandidType], vals : [Candid], _options : ?Candid.Options) : Result.Result<Blob, Text> {
        let options = Option.get(_options, Candid.defaultOptions);

        let single_function_encoding = switch (Candid.encode(vals, ?options)) {
            case (#ok(blob)) blob;
            case (#err(err)) {
                Debug.print("encode function failed: " # err);
                return #err("encode function failed: " #err);
            };
        };

        let encoder = Candid.TypedSerializer.new(types, ?options);
        let encoded_blob_res = Candid.TypedSerializer.encode(encoder, vals);
        let encoder_instance_blob = switch (encoded_blob_res) {
            case (#ok(blob)) blob;
            case (#err(err)) {
                Debug.print("encoder instance failed: " # err);
                return #err("encoder instance failed: " # err);
            };
        };

        if (encoder_instance_blob != single_function_encoding) {

            let single_function_encoding_with_types = switch (Candid.encode(vals, ?{ options with types = ?Candid.formatCandidType(types, ?options.renameKeys) })) {
                case (#ok(blob)) blob;
                case (#err(err)) {
                    Debug.print("encode function failed: " # err);
                    return #err("encode function failed: " #err);
                };
            };

            if (encoder_instance_blob != single_function_encoding_with_types) {
                Debug.print("Encoded blob does not match the original encoding:");
                Debug.print("Single function: " # debug_show (Blob.toArray(single_function_encoding_with_types)));
                Debug.print("Encoder instance: " # debug_show (Blob.toArray(encoder_instance_blob)));
                return #err("Encoded blob does not match the original encoding: " # debug_show ({ single_function_encoding_with_types; encoder_instance_blob }));
            };
        };

        // assert Candid.TypedSerializer.equal(encoder, Candid.TypedSerializer.fromBlob(encoder_instance_blob, [], ?options));

        return #ok(encoder_instance_blob);
    };

    public func decode_with_types(types : [Candid.CandidType], record_keys : [Text], blob : Blob, _options : ?Candid.Options) : Result.Result<[Candid], Text> {
        let options = Option.get(_options, Candid.defaultOptions);

        let single_function_decoding = switch (Candid.decode(blob, record_keys, ?options)) {
            case (#ok(vals)) vals;
            case (#err(err)) {
                Debug.print("decode function failed: " # err);
                return #err("decode function failed: " # err);
            };
        };

        let decoder = Candid.TypedSerializer.fromBlob(blob, record_keys, ?options);
        let decoded_vals_res = Candid.TypedSerializer.decode(decoder, blob);
        let decoder_instance_vals = switch (decoded_vals_res) {
            case (#ok(vals)) vals;
            case (#err(err)) {
                Debug.print("decoder instance failed: " # err);
                return #err("decoder instance failed: " # err);
            };
        };

        if (decoder_instance_vals != single_function_decoding) {
            Debug.print("Decoded values do not match the original decoding:");
            Debug.print("Candid.decode() function: " # debug_show (single_function_decoding));
            Debug.print("TypedSerializer instance: " # debug_show (decoder_instance_vals));
            return #err("Decoded values do not match the original decoding: " # debug_show ({ single_function_decoding; decoder_instance_vals }));
        };

        // !important: the decoder instance should be equal to a new TypedSerializer created with the same types and options
        // if (not Candid.TypedSerializer.equal(decoder, Candid.TypedSerializer.new(types, ?options))) {
        //     Debug.print("Decoder and new TypedSerializer are not equal.");
        //     Debug.print("Decoder: " # Candid.TypedSerializer.toText(decoder));
        //     Debug.print("New TypedSerializer: " # Candid.TypedSerializer.toText(Candid.TypedSerializer.new(types, ?options)));
        //     return #err("Decoder and new TypedSerializer are not equal.");
        // };

        return #ok(decoder_instance_vals);
    };

};
