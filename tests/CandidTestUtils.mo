// @testmode wasi
import Array "mo:core@2.4/Array";
import Blob "mo:core@2.4/Blob";
import Debug "mo:core@2.4/Debug";
import Iter "mo:core@2.4/Iter";
import Nat "mo:core@2.4/Nat";
import Principal "mo:core@2.4/Principal";
import Result "mo:core@2.4/Result";
import Option "mo:core@2.4/Option";

import { test; suite } "mo:test";
import Map "mo:map@9.0/Map";
import Itertools "mo:itertools@0.2.2/Iter";

import Serde "../src";
import Candid "../src/Candid";
import Encoder "../src/Candid/Blob/Encoder";

import { toArgs; toArgType; fromArgs; fromArgType } "helpers/motoko_candid_utils";
import ValidationDecoder "mo:candid/Decoder";
import ValidationEncoder "mo:candid/Encoder";
import ValidationType "mo:candid/Type";
import ValidationArg "mo:candid/Arg";
import Runtime "mo:core/Runtime";



module {
    type Candid = Candid.Candid;

    type CandidType = Candid.CandidType;

    let Validator = {
        Encoder = ValidationEncoder;
        Decoder = ValidationDecoder;
    };

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

    func empty_map() : Map.Map<Text, Text> {
        Map.new<Text, Text>()
    };

    public func validator_encoding(candid_values : [Candid.Candid]) : Blob {
        let #ok(args) = toArgs(candid_values, empty_map()) else Runtime.trap("validator_encoding: toArgs failed");
        Blob.fromArray(Validator.Encoder.toBytes(args));
    };

    public func validate_encoding(candid_values : [Candid.Candid], encoded: Blob) : Bool {
        Debug.print("candid_values: " # debug_show candid_values);

        let expected = validator_encoding(candid_values);

        Debug.print("encoded: " # debug_show (encoded));
        Debug.print("expected: " # debug_show(expected));

        return encoded == expected;
    };

    public func validate_encoding_with_types(candid_values : [Candid.Candid], types : [CandidType], encoded: Blob) : Bool {

        let #ok(args) = toArgs(candid_values, empty_map());
        let arg_types = Array.map<CandidType, ValidationType.Type>(types, toArgType);

        let arg_types_iter = arg_types.vals();
        let augmented_args = Array.map(
            args,
            func(arg : ValidationArg.Arg) : ValidationArg.Arg {
                let ?arg_type = arg_types_iter.next();

                { arg with type_ = arg_type };
            },
        );

        let expected = Blob.fromArray(Validator.Encoder.toBytes(augmented_args));

        Debug.print("encoded: " # debug_show (encoded));
        Debug.print("expected: " # debug_show(expected));
        
        return encoded == expected;
    };

    public func validate_decoding(decoded : [Candid.Candid], encoded: Blob, field_names: [Text]) : Bool {

        let expected_args = switch(Validator.Decoder.fromBytes(encoded.vals())){
            case (?args) args;
            case (null) Runtime.trap("validate_decoding: decoding failed");
        };

        let expected = switch (fromArgs(expected_args, empty_map(), field_names)) {
            case (#ok(vals)) vals;
            case (#err(err)) {
                Debug.print("Decoding failed: " # err);
                return false;
            };
        };

        Debug.print("decoded: " # debug_show decoded);
        Debug.print("expected: " # debug_show expected);

        return Itertools.all(
            Itertools.zip(decoded.vals(), expected.vals()),
            func((a, b): (Candid, Candid)) : Bool {Candid.equal(a, b)},
        );
    };

    public func validate_encoding_by_decoding(candid_values: [Candid.Candid], encoded: Blob, field_names: [Text]) : Bool {

        return validate_decoding(candid_values, encoded, field_names);
    };

    // public func validate_decoding_with_types(encoded: Blob, types : [CandidType], decoded : [Candid.Candid]) : Bool {
    //     let expected = switch (fromArgs(Validator.Decoder.fromBytes(encoded.vals(), Array.map<CandidType, ValidationType.Type>(types, toArgType)))) {
    //         case (#ok(vals)) vals;
    //         case (#err(err)) {
    //             Debug.print("Decoding failed: " # err);
    //             return false;
    //         };
    //     };

    //     Debug.print("(decoded, expected): " # debug_show (decoded, expected));

    //     return decoded == expected;
    // };

};
