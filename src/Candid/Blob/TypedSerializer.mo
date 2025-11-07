import Array "mo:base@0.16.0/Array";
import Blob "mo:base@0.16.0/Blob";
import Buffer "mo:base@0.16.0/Buffer";
import Result "mo:base@0.16.0/Result";
import Nat64 "mo:base@0.16.0/Nat64";
import Nat8 "mo:base@0.16.0/Nat8";
import Nat32 "mo:base@0.16.0/Nat32";
import Nat "mo:base@0.16.0/Nat";
import Iter "mo:base@0.16.0/Iter";
import Text "mo:base@0.16.0/Text";
import Order "mo:base@0.16.0/Order";
import TrieMap "mo:base@0.16.0/TrieMap";
import Option "mo:base@0.16.0/Option";
import Debug "mo:base@0.16.0/Debug";

import Map "mo:map@9.0.1/Map";
import Set "mo:map@9.0.1/Set";
import ByteUtils "mo:byte-utils@0.1.2";

import T "../Types";
import CandidUtils "CandidUtils";
import Encoder "Encoder";
import Decoder "Decoder";

import Utils "../../Utils";

module TypedSerializer {

    type Iter<A> = Iter.Iter<A>;
    type Result<A, B> = Result.Result<A, B>;

    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    type Buffer<A> = Buffer.Buffer<A>;
    type Hash = Nat32;
    type Map<K, V> = Map.Map<K, V>;
    type Set<A> = Set.Set<A>;
    type Order = Order.Order;

    type CandidType = T.CandidType;
    type ShallowCandidTypes = T.ShallowCandidTypes;

    let { n32hash; thash } = Map;
    let { nhash } = Set;

    // Constants
    let C = {
        COUNTER = {
            COMPOUND_TYPE = 0;
            PRIMITIVE_TYPE = 1;
            VALUE = 2;
        };
        BYTES_INDEX = 0;
    };

    public type TypedSerializer = {
        // Encoder types: keep original field names and use renaming_map during encoding
        // to convert from old names to new names in the output
        encoder_candid_types : [CandidType];

        // Decoder types: store new field names so decoding can convert
        // from new names back to old names using record_key_map
        decoder_candid_types : [CandidType];

        encoded_type_header : [Nat8];
        renaming_map : Map<Text, Text>;
        record_key_map : Map<Nat32, Text>;
        options : T.Options;
        compound_types : [ShallowCandidTypes];
        recursive_types_map : Map<Nat, CandidType>;
    };

    func read(bytes : Blob, state : [var Nat]) : Nat8 {
        let byte = bytes.get(state[C.BYTES_INDEX]);
        state[C.BYTES_INDEX] += 1;
        byte;
    };

    // Helper function
    func formatVariantKey(key : Text) : Text {
        let opt = Text.stripStart(key, #text("#"));
        switch (opt) {
            case (?stripped_text) stripped_text;
            case (null) key;
        };
    };

    // https://en.wikipedia.org/wiki/LEB128
    func decode_leb128(bytes : Blob, state : [var Nat]) : Nat {
        var n64 : Nat64 = 0;
        var shift : Nat64 = 0;

        label decoding_leb loop {
            let byte = read(bytes, state);

            n64 |= (Nat64.fromNat(Nat8.toNat(byte & 0x7f)) << shift);

            if (byte & 0x80 == 0) break decoding_leb;
            shift += 7;
        };

        Nat64.toNat(n64);
    };

    // Local encoder function to replace Encoder.Encoder.new
    func create_encoded_type_header(
        _candid_types : [CandidType],
        _options : T.Options,
        renaming_map : Map<Text, Text>,
    ) : [Nat8] {
        let options = _options;

        let candid_types = switch (options.types) {
            case (?types) types;
            case (_) Array.map(
                _candid_types,
                func(candid_type : CandidType) : CandidType {
                    CandidUtils.format_candid_type(candid_type, renaming_map);
                },
            );
        };

        let compound_type_buffer = Buffer.Buffer<Nat8>(200);
        let candid_type_buffer = Buffer.Buffer<Nat8>(200);

        let counter = [var 0];

        // Only encode the types, not the values
        var i = 0;
        let unique_compound_type_map = Map.new<Text, Nat>();

        while (i < candid_types.size()) {
            Encoder.encode_type_only(
                candid_types[i],
                compound_type_buffer,
                candid_type_buffer,
                renaming_map,
                unique_compound_type_map,
                counter,
                false,
            );
            i += 1;
        };

        let candid_magic_bytes_buffer = Buffer.fromArray<Nat8>([0x44, 0x49, 0x44, 0x4C]); // 'DIDL' magic bytes

        // add compound type to the buffer
        let compound_type_size_bytes = Buffer.Buffer<Nat8>(8);
        ByteUtils.Buffer.addLEB128_64(compound_type_size_bytes, Nat64.fromNat(counter[C.COUNTER.COMPOUND_TYPE]));

        // add primitive type to the buffer
        let candid_type_size_bytes = Buffer.Buffer<Nat8>(8);
        ByteUtils.Buffer.addLEB128_64(candid_type_size_bytes, Nat64.fromNat(candid_types.size()));

        let total_size = candid_magic_bytes_buffer.size() + compound_type_size_bytes.size() + compound_type_buffer.size() + candid_type_size_bytes.size() + candid_type_buffer.size();

        let sequence = [
            candid_magic_bytes_buffer,
            compound_type_size_bytes,
            compound_type_buffer,
            candid_type_size_bytes,
            candid_type_buffer,
        ];

        i := 0;
        var j = 0;

        Array.tabulate<Nat8>(
            total_size,
            func(_ : Nat) : Nat8 {
                var buffer = sequence[i];
                while (j >= buffer.size()) {
                    j := 0;
                    i += 1;
                    buffer := sequence[i];
                };

                let byte = buffer.get(j);
                j += 1;
                byte;
            },
        );
    };

    func extract_record_or_variant_keys(schema : T.CandidType) : [Text] {
        let buffer = Buffer.Buffer<Text>(8);

        func extract(schema : T.CandidType) {
            switch (schema) {
                case (#Record(fields) or #Map(fields)) {
                    for ((name, value) in fields.vals()) {
                        buffer.add(name);
                        extract(value);
                    };
                };
                case (#Variant(variants)) {
                    for ((name, value) in variants.vals()) {
                        buffer.add(name);
                        extract(value);
                    };
                };
                case (#Tuple(types)) {
                    for (tuple_type in types.vals()) {
                        extract(tuple_type);
                    };
                };
                case (#Option(inner)) { extract(inner) };
                case (#Array(inner)) { extract(inner) };
                case (_) {};
            };
        };

        extract(schema);

        Buffer.toArray(buffer);
    };

    func is_map_equal<K, V>(map1 : Map<K, V>, map2 : Map<K, V>, hasher : Map.HashUtils<K>, is_value_equal : (V, V) -> Bool) : Bool {
        if (Map.size(map1) != Map.size(map2)) return false;

        for ((k, v) in Map.entries(map1)) {
            switch (Map.get(map2, hasher, k)) {
                case (?v2) if (is_value_equal(v, v2)) {};
                case (_) return false;
            };
        };

        true;
    };

    public func equal(self : TypedSerializer, other : TypedSerializer) : Bool {
        if (self.encoder_candid_types != other.encoder_candid_types) return false;
        if (self.decoder_candid_types != other.decoder_candid_types) return false;
        if (self.encoded_type_header != other.encoded_type_header) return false;
        if (not is_map_equal(self.renaming_map, other.renaming_map, thash, Text.equal)) return false;
        if (not is_map_equal(self.record_key_map, other.record_key_map, n32hash, Text.equal)) return false;
        if (self.options != other.options) return false;
        if (self.compound_types != other.compound_types) return false;

        // Define a function to compare CandidType values
        func candid_type_equal(t1 : CandidType, t2 : CandidType) : Bool {
            t1 == t2;
        };
        if (not is_map_equal(self.recursive_types_map, other.recursive_types_map, Map.nhash, candid_type_equal)) return false;

        true;
    };

    // add a print fn
    public func toText(self : TypedSerializer) : Text {
        "TypedSerializer {\n"
        # "  encoder_candid_types: " # debug_show (self.encoder_candid_types) # "\n"
        # "  decoder_candid_types: " # debug_show (self.decoder_candid_types) # "\n"
        # "  encoded_type_header: " # debug_show (self.encoded_type_header) # "\n"
        # "  renaming_map: " # debug_show (Map.toArray(self.renaming_map)) # "\n"
        # "  record_key_map: " # debug_show (Map.toArray(self.record_key_map)) # "\n"
        # "  options: " # debug_show (self.options) # "\n"
        # "  compound_types: " # debug_show (self.compound_types) # "\n"
        # "  recursive_types_map: " # debug_show (Map.toArray(self.recursive_types_map)) # "\n"
        # "}";
    };

    /// Creates a new TypedSerializer from Candid types
    public func new(_candid_types : [CandidType], _options : ?T.Options) : TypedSerializer {
        let options = Option.get(_options, T.defaultOptions);

        let renaming_map = Map.new<Text, Text>();
        for ((k, v) in options.renameKeys.vals()) {
            ignore Map.put(renaming_map, thash, k, v);
        };

        // Encoder types: original types that will use renaming_map during encoding
        let encoder_candid_types = switch (options.types) {
            case (?types) types;
            case (_) Array.map(
                _candid_types,
                func(candid_type : CandidType) : CandidType {
                    CandidUtils.format_candid_type(candid_type, renaming_map);
                },
            );
        };

        // Decoder types are the same as encoder types - renaming happens during value decoding
        let decoder_candid_types = switch (options.types) {
            case (?types) types;
            case (_) Array.map(
                _candid_types,
                func(candid_type : CandidType) : CandidType {
                    CandidUtils.sort_candid_type(candid_type);
                },
            );
        };

        // Decoder types: types with renamed fields for decoding

        // Collect record keys from all encoder_candid_types entries
        let record_keys_buffer = Buffer.Buffer<Text>(8);
        for (candid_type in encoder_candid_types.vals()) {
            let keys = extract_record_or_variant_keys(candid_type);
            for (key in keys.vals()) {
                record_keys_buffer.add(key);
            };
        };
        let record_keys = Buffer.toArray(record_keys_buffer);

        let record_key_map = Map.new<Nat32, Text>();

        var i = 0;

        while (i < record_keys.size()) {
            let key = formatVariantKey(record_keys[i]);
            let hash = Utils.hash_record_key(key);
            ignore Map.put(record_key_map, n32hash, hash, key);
            i += 1;
        };

        ignore do ? {
            let key_pairs_to_rename = options.renameKeys;

            var j = 0;
            while (j < key_pairs_to_rename.size()) {
                let original_key = formatVariantKey(key_pairs_to_rename[j].0);
                let new_key = formatVariantKey(key_pairs_to_rename[j].1);

                let hash = Utils.hash_record_key(original_key);
                ignore Map.put(record_key_map, n32hash, hash, new_key);

                j += 1;
            };
        };

        // Use encoder types for the encoded type header
        let encoded_type_header = create_encoded_type_header(encoder_candid_types, options, renaming_map);

        {
            encoded_type_header;
            encoder_candid_types;
            decoder_candid_types;
            renaming_map;
            record_key_map;
            options;
            compound_types = []; // Will be populated if needed
            recursive_types_map = Map.new<Nat, CandidType>(); // Initialize empty map
        } : TypedSerializer;
    };

    /// Creates a new TypedSerializer from a blob (extracts types from the blob)
    public func fromBlob(blob : Blob, record_keys : [Text], _options : ?T.Options) : TypedSerializer {
        let options = Option.get(_options, T.defaultOptions);

        let record_key_map = Map.new<Nat32, Text>();

        var i = 0;
        while (i < record_keys.size()) {
            let key = formatVariantKey(record_keys[i]);
            let hash = Utils.hash_record_key(key);
            ignore Map.put(record_key_map, n32hash, hash, key);
            i += 1;
        };

        let renaming_map = Map.new<Text, Text>();

        ignore do ? {
            let key_pairs_to_rename = options.renameKeys;

            var j = 0;
            while (j < key_pairs_to_rename.size()) {
                let original_key = formatVariantKey(key_pairs_to_rename[j].0);
                let new_key = formatVariantKey(key_pairs_to_rename[j].1);

                let hash = Utils.hash_record_key(original_key);

                ignore Map.put(renaming_map, thash, original_key, new_key);

                j += 1;
            };
        };

        let bytes = blob;
        let state : [var Nat] = [var 0];

        let magic = Array.tabulate(4, func(_ : Nat) : Nat8 = read(bytes, state));
        assert (magic == [0x44, 0x49, 0x44, 0x4c]);

        let total_compound_types = decode_leb128(bytes, state);
        let compound_types = Decoder.extract_compound_types(bytes, state, total_compound_types, record_key_map);
        let recursive_types_map = Map.new<Nat, CandidType>();
        let extracted_candid_types = Decoder.build_types(bytes, state, compound_types, recursive_types_map);

        let type_header_size = state[C.BYTES_INDEX];
        let encoded_type_header = Array.tabulate(type_header_size, func(i : Nat) : Nat8 = blob.get(i));

        // Generate encoded_type_header using the same logic as new() to ensure consistency
        let _encoded_type_header2 = create_encoded_type_header(extracted_candid_types, options, renaming_map);
        // assert (encoded_type_header == _encoded_type_header2);

        {
            encoder_candid_types = extracted_candid_types;
            decoder_candid_types = extracted_candid_types;
            record_key_map;
            options;
            compound_types = []; // Keep consistent with new() function
            encoded_type_header;
            renaming_map;
            recursive_types_map;
        };
    };

    /// Encodes values using the precomputed types in this TypedSerializer
    public func encode(self : TypedSerializer, candid_values : [Candid]) : Result<Blob, Text> {
        if (candid_values.size() != self.encoder_candid_types.size()) {
            return #err("encode: candid_values size does not match encoder_candid_types size");
        };

        let value_buffer = Buffer.Buffer<Nat8>(400);
        let recursive_map = Map.new<Text, Text>();
        let counter = [var 0];
        let unique_compound_type_map = Map.new<Text, Nat>();

        var i = 0;
        while (i < candid_values.size()) {
            ignore Encoder.encode_value_only(
                self.encoder_candid_types[i],
                candid_values[i],
                value_buffer,
                self.renaming_map,
                unique_compound_type_map,
                recursive_map,
                counter,
                false,
            );
            i += 1;
        };

        #ok(
            Blob.fromArray(
                Array.append(
                    self.encoded_type_header,
                    Buffer.toArray(value_buffer),
                )
            )
        );
    };

    /// Decodes values from a full candid blob using precomputed types
    public func decode(self : TypedSerializer, candid_blob : Blob) : Result<[Candid], Text> {
        let bytes = candid_blob;
        let state : [var Nat] = [var 0];

        // Verify magic number
        let magic = Array.tabulate(4, func(_ : Nat) : Nat8 = read(bytes, state));
        if (magic != [0x44, 0x49, 0x44, 0x4c]) {
            return #err("Invalid Magic Number");
        };

        // Since we have the precomputed encoded_type_header, we can directly jump to the values section
        // instead of parsing and skipping the type section
        state[C.BYTES_INDEX] := self.encoded_type_header.size();

        // Use precomputed types and recursive types map for decoding values
        Decoder.decode_candid_values(bytes, self.decoder_candid_types, state, self.options, self.renaming_map, self.recursive_types_map);
    };

};
