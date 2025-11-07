import Array "mo:base@0.16.0/Array";
import Blob "mo:base@0.16.0/Blob";
import Buffer "mo:base@0.16.0/Buffer";
import Debug "mo:base@0.16.0/Debug";
import Result "mo:base@0.16.0/Result";
import Nat64 "mo:base@0.16.0/Nat64";
import Int8 "mo:base@0.16.0/Int8";
import Int32 "mo:base@0.16.0/Int32";
import Nat8 "mo:base@0.16.0/Nat8";
import Nat32 "mo:base@0.16.0/Nat32";
import Int64 "mo:base@0.16.0/Int64";
import Nat "mo:base@0.16.0/Nat";
import Int "mo:base@0.16.0/Int";
import Iter "mo:base@0.16.0/Iter";
import Principal "mo:base@0.16.0/Principal";
import Text "mo:base@0.16.0/Text";
import Order "mo:base@0.16.0/Order";
import Int16 "mo:base@0.16.0/Int16";
import TrieMap "mo:base@0.16.0/TrieMap";
import Option "mo:base@0.16.0/Option";

import Map "mo:map@9.0.1/Map";
import Set "mo:map@9.0.1/Set";
import ByteUtils "mo:byte-utils@0.1.2";

import T "../Types";
import Utils "../../Utils";
import CandidUtils "CandidUtils";

module {
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

    let { nhash } = Set;
    let { n32hash; thash } = Map;

    /// Decodes a blob encoded in the candid format into a list of the [Candid](./Types.mo#Candid) type in motoko
    ///
    /// ### Inputs
    /// - **blob** -  A blob encoded in the candid format
    /// - **record_keys** - The record keys to use when decoding a record.
    /// - **options** - An optional arguement to specify options for decoding.
    public func decode(blob : Blob, record_keys : [Text], options : ?T.Options) : Result<[Candid], Text> {
        one_shot(blob, record_keys, options);
    };

    public func decodeOne(blob : Blob, record_keys : [Text], options : ?T.Options) : Result<Candid, Text> {
        let result = one_shot(blob, record_keys, options);

        switch (result) {
            case (#ok(candid_values)) {
                if (candid_values.size() == 1) {
                    #ok(candid_values[0]);
                } else {
                    #err("Expected one value in blob, instead got " # debug_show (candid_values.size()));
                };
            };
            case (#err(msg)) #err(msg);
        };
    };

    ///
    type CandidBlobSequences = {
        magic : Blob;
        compound_types : Blob;
        types : Blob;
        values : Blob;
    };

    public func split(blob : Blob, options : ?T.Options) : Result<CandidBlobSequences, Text> {
        let bytes = blob;

        let state : [var Nat] = [var 0];

        let magic = Array.tabulate(4, func(i : Nat) : Nat8 = read(bytes, state));

        if (magic != [0x44, 0x49, 0x44, 0x4c]) {
            return #err("Invalid Magic Number");
        };

        let compound_types_start_index = state[C.BYTES_INDEX];
        let total_compound_types = decode_leb128(bytes, state);
        skip_compound_types(bytes, state, total_compound_types);

        let types_start_index = state[C.BYTES_INDEX];

        skip_types(bytes, state);

        let values_start_index = state[C.BYTES_INDEX];

        let sequences : CandidBlobSequences = {
            magic = Blob.fromArray(magic);
            compound_types = Blob.fromArray(Utils.blob_slice(bytes, compound_types_start_index, types_start_index));
            types = Blob.fromArray(Utils.blob_slice(bytes, types_start_index, values_start_index));
            values = Blob.fromArray(Utils.blob_slice(bytes, values_start_index, bytes.size()));
        };

        #ok(sequences);
    };

    public func extract_values_sequence(blob : Blob) : Result<Blob, Text> {
        let bytes = blob;

        let state : [var Nat] = [var 0];

        let magic = Array.tabulate(4, func(i : Nat) : Nat8 = read(bytes, state));

        if (magic != [0x44, 0x49, 0x44, 0x4c]) {
            return #err("Invalid Magic Number");
        };

        let total_compound_types = decode_leb128(bytes, state);
        skip_compound_types(bytes, state, total_compound_types);

        skip_types(bytes, state);

        let values_start_index = state[C.BYTES_INDEX];
        let values_sequence = Blob.fromArray(Utils.blob_slice(bytes, values_start_index, bytes.size()));

        #ok(values_sequence)

    };

    public func one_shot(blob : Blob, record_keys : [Text], options : ?T.Options) : Result<[Candid], Text> {

        let record_key_map = Map.new<Nat32, Text>();

        var i = 0;
        while (i < record_keys.size()) {
            let key = formatVariantKey(record_keys[i]);
            let hash = Utils.hash_record_key(key);
            ignore Map.put(record_key_map, n32hash, hash, key);
            i += 1;
        };

        ignore do ? {
            let key_pairs_to_rename = options!.renameKeys;

            var i = 0;
            while (i < key_pairs_to_rename.size()) {
                let original_key = formatVariantKey(key_pairs_to_rename[i].0);
                let new_key = formatVariantKey(key_pairs_to_rename[i].1);

                let hash = Utils.hash_record_key(original_key);
                // ignore Map.put(record_key_map, n32hash, hash, new_key);

                i += 1;
            };

        };

        one_shot_decode(blob, record_key_map, Option.get(options, T.defaultOptions));
    };

    func read(bytes : Blob, state : [var Nat]) : Nat8 {
        let byte = bytes.get(state[C.BYTES_INDEX]);
        state[C.BYTES_INDEX] += 1;
        byte;
    };

    func peek(bytes : Blob, state : [var Nat]) : Nat8 {
        bytes.get(state[C.BYTES_INDEX]);
    };

    // Helper function to create an iterator from read function
    func createByteIterator(bytes : Blob, state : [var Nat]) : Iter.Iter<Nat8> {
        object {
            public func next() : ?Nat8 {
                let i = state[C.BYTES_INDEX];
                if (i < bytes.size()) {
                    let byte = bytes[i];
                    state[C.BYTES_INDEX] += 1;
                    ?byte;
                } else {
                    null;
                };
            };
        };
    };

    // Iterator-based helper functions
    func read_from_iter(iter : Iter.Iter<Nat8>) : Nat8 {
        switch (iter.next()) {
            case (?byte) byte;
            case (null) Debug.trap("Unexpected end of data stream");
        };
    };

    func decode_leb128_from_iter(iter : Iter.Iter<Nat8>) : Nat {
        var n64 : Nat64 = 0;
        var shift : Nat64 = 0;

        label decoding_leb loop {
            let byte = read_from_iter(iter);

            n64 |= (Nat64.fromNat(Nat8.toNat(byte & 0x7f)) << shift);

            if (byte & 0x80 == 0) break decoding_leb;
            shift += 7;
        };

        Nat64.toNat(n64);
    };

    func decode_signed_leb_64_from_iter(iter : Iter.Iter<Nat8>) : Int {
        var result : Nat64 = 0;
        var shift : Nat64 = 0;
        var byte : Nat8 = 0;
        var i = 0;

        label analyzing loop {
            byte := read_from_iter(iter);
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

        Int64.toInt(Int64.fromNat64(result));
    };

    func code_to_primitive_type(code : Nat8) : CandidType {
        if (code == T.TypeCode.Null) {
            #Null;
        } else if (code == T.TypeCode.Bool) {
            #Bool;
        } else if (code == T.TypeCode.Nat) {
            #Nat;
        } else if (code == T.TypeCode.Nat8) {
            #Nat8;
        } else if (code == T.TypeCode.Nat16) {
            #Nat16;
        } else if (code == T.TypeCode.Nat32) {
            #Nat32;
        } else if (code == T.TypeCode.Nat64) {
            #Nat64;
        } else if (code == T.TypeCode.Int) {
            #Int;
        } else if (code == T.TypeCode.Int8) {
            #Int8;
        } else if (code == T.TypeCode.Int16) {
            #Int16;
        } else if (code == T.TypeCode.Int32) {
            #Int32;
        } else if (code == T.TypeCode.Int64) {
            #Int64;
        } else if (code == T.TypeCode.Float) {
            #Float;
        } else if (code == T.TypeCode.Text) {
            #Text;
        } else if (code == T.TypeCode.Principal) {
            #Principal;
        } else if (code == T.TypeCode.Empty) {
            #Empty;
        } else {
            Debug.trap("code [" # debug_show code # "] does not belong to a primitive type");
        };
    };

    func is_code_primitive_type(code : Nat8) : Bool {
        (code >= 0x70 and code <= 0x7f) or (code == 0x6f) or (code == 0x68);
    };

    public func extract_compound_types(bytes : Blob, state : [var Nat], total_compound_types : Nat, record_key_map : Map<Nat32, Text>) : [ShallowCandidTypes] {

        func extract_compound_type(i : Nat) : ShallowCandidTypes {
            let compound_type_code = read(bytes, state);

            let shallow_type = if (compound_type_code == T.TypeCode.Option) {
                let code = peek(bytes, state);
                let code_or_ref = if (is_code_primitive_type(code)) {
                    ignore read(bytes, state);
                    Nat8.toNat(code);
                } else {
                    let ref_pos = decode_leb128(bytes, state);
                };

                #OptionRef(code_or_ref);
            } else if (compound_type_code == T.TypeCode.Array) {
                let code = peek(bytes, state);
                let code_or_ref = if (is_code_primitive_type(code)) {
                    ignore read(bytes, state);
                    Nat8.toNat(code);
                } else {
                    let ref_pos = decode_leb128(bytes, state);
                };

                #ArrayRef(code_or_ref);
            } else if (compound_type_code == T.TypeCode.Record or compound_type_code == T.TypeCode.Variant) {
                let size = decode_leb128(bytes, state);
                let fields = Array.tabulate<(Text, Nat)>(
                    size,
                    func(i : Nat) : (Text, Nat) {
                        let hash = decode_leb128(bytes, state) |> Nat32.fromNat(_);
                        let field_key = switch (Map.get(record_key_map, n32hash, hash)) {
                            case (?field_key) field_key;
                            case (null) debug_show hash;
                        };

                        let code = peek(bytes, state);
                        let field_code_or_pos = if (is_code_primitive_type(code)) {
                            ignore read(bytes, state);
                            Nat8.toNat(code);
                        } else {
                            let ref_pos = decode_leb128(bytes, state);
                        };

                        (field_key, field_code_or_pos);
                    },
                );

                if (compound_type_code == T.TypeCode.Record) {
                    #RecordRef(fields);
                } else {
                    #VariantRef(fields);
                };
            } else {
                Debug.trap("extract_compound_types(): expected compound type instead found " # debug_show (compound_type_code));
            };

            shallow_type;
        };

        Array.tabulate(total_compound_types, extract_compound_type);
    };

    func build_compound_type(compound_types : [ShallowCandidTypes], start_pos : Nat, recursive_types_map : Map<Nat, CandidType>) : CandidType {
        func _build_compound_type(compound_types : [ShallowCandidTypes], start_pos : Nat, visited : Set<Nat>, is_recursive_set : Set<Nat>, recursive_types_map : Map<Nat, CandidType>) : CandidType {
            var pos = start_pos;

            func resolve_field_types((field_key, ref_pos) : (Text, Nat)) : ((Text, CandidType)) {
                let visited_size = Set.size(visited);
                let resolved_type : CandidType = if (is_code_primitive_type(Nat8.fromNat(ref_pos))) {
                    code_to_primitive_type(Nat8.fromNat(ref_pos));
                } else {
                    _build_compound_type(compound_types, ref_pos, visited, is_recursive_set, recursive_types_map);
                };

                while (Set.size(visited) > visited_size) {
                    ignore Set.pop(visited, nhash);
                };

                (field_key, resolved_type);
            };

            switch (Map.get(recursive_types_map, nhash, pos)) {
                case (?candid_type) return candid_type;
                case (null) {};
            };

            if (Set.has(visited, nhash, pos) and not Set.has(is_recursive_set, nhash, pos)) {
                ignore Set.put(is_recursive_set, nhash, pos);
                return #Recursive(pos);
            };

            ignore Set.put(visited, nhash, pos);

            let resolved_compound_type = switch (compound_types.get(pos)) {
                case (#OptionRef(ref_pos)) {
                    let ref_type = if (is_code_primitive_type(Nat8.fromNat(ref_pos))) {
                        code_to_primitive_type(Nat8.fromNat(ref_pos));
                    } else {
                        _build_compound_type(compound_types, ref_pos, visited, is_recursive_set, recursive_types_map);
                    };

                    #Option(ref_type);
                };
                case (#ArrayRef(ref_pos)) {
                    let ref_type = if (is_code_primitive_type(Nat8.fromNat(ref_pos))) {
                        code_to_primitive_type(Nat8.fromNat(ref_pos));
                    } else {
                        _build_compound_type(compound_types, ref_pos, visited, is_recursive_set, recursive_types_map);
                    };
                    #Array(ref_type);
                };
                case (#RecordRef(fields)) {
                    let resolved_fields = Array.map<(Text, Nat), (Text, CandidType)>(fields, resolve_field_types);
                    #Record(resolved_fields);
                };
                case (#VariantRef(fields)) {
                    let resolved_fields = Array.map<(Text, Nat), (Text, CandidType)>(fields, resolve_field_types);
                    #Variant(resolved_fields);
                };
            };

            if (Set.has(is_recursive_set, nhash, pos) and not Map.has(recursive_types_map, nhash, pos)) {
                ignore Map.put(recursive_types_map, nhash, pos, resolved_compound_type);
            };

            resolved_compound_type;
        };

        let visited = Set.new<Nat>();
        let is_recursive_set = Set.new<Nat>();

        _build_compound_type(compound_types, start_pos, visited, is_recursive_set, recursive_types_map);
    };

    public func build_types(bytes : Blob, state : [var Nat], compound_types : [ShallowCandidTypes], recursive_types_map : Map<Nat, CandidType>) : [CandidType] {
        let total_candid_types = decode_leb128(bytes, state);

        let candid_types = Array.tabulate(
            total_candid_types,
            func(i : Nat) : CandidType {
                let code = peek(bytes, state);
                let candid_type = if (is_code_primitive_type(code)) {
                    ignore read(bytes, state);
                    let primitive_type = code_to_primitive_type(code);
                    primitive_type;
                } else {
                    let start_pos = decode_leb128(bytes, state);
                    let compound_type = build_compound_type(compound_types, start_pos, recursive_types_map);
                    compound_type;
                };

                CandidUtils.sort_candid_type(candid_type);

            },
        );

        (candid_types);
    };

    public func skip_compound_types(bytes : Blob, state : [var Nat], total_compound_types : Nat) {
        var i = 0;
        while (i < total_compound_types) {
            let compound_type_code = read(bytes, state);

            if (compound_type_code == T.TypeCode.Option) {
                let code = peek(bytes, state);
                if (is_code_primitive_type(code)) {
                    ignore read(bytes, state); // advance past code
                } else {
                    ignore decode_leb128(bytes, state); // start_pos
                };
            } else if (compound_type_code == T.TypeCode.Array) {
                let code = peek(bytes, state);
                if (is_code_primitive_type(code)) {
                    ignore read(bytes, state); // advance past code
                } else {
                    ignore decode_leb128(bytes, state); // start_pos
                };
            } else if (compound_type_code == T.TypeCode.Record or compound_type_code == T.TypeCode.Variant) {
                let size = decode_leb128(bytes, state);
                var i = 0;

                while (i < size) {
                    ignore decode_leb128(bytes, state); // hash

                    let code = peek(bytes, state);
                    if (is_code_primitive_type(code)) {
                        ignore read(bytes, state); // advance past code
                    } else {
                        ignore decode_leb128(bytes, state); // start_pos
                    };

                    i += 1;
                };
            } else {
                Debug.trap("code [" # debug_show compound_type_code # "] does not belong to a compound type");
            };

            i += 1;
        };
    };

    public func skip_types(bytes : Blob, state : [var Nat]) {

        let total_candid_types = decode_leb128(bytes, state);

        var i = 0;

        while (i < total_candid_types) {
            let code = peek(bytes, state);
            if (is_code_primitive_type(code)) {
                ignore read(bytes, state); // advance past code
            } else {
                ignore decode_leb128(bytes, state); // start_pos
            };

            i += 1;
        };
    };

    public func one_shot_decode(candid_blob : Blob, record_key_map : Map<Nat32, Text>, options : T.Options) : Result<[Candid], Text> {
        let bytes = candid_blob;
        // let stream = BitBuffer.fromArray(bytes);

        let is_types_set = Option.isSome(options.types);

        var candid_types = Option.get(options.types, []);

        let state : [var Nat] = [var 0];

        let magic = Array.tabulate(4, func(i : Nat) : Nat8 = read(bytes, state));

        if (magic != [0x44, 0x49, 0x44, 0x4c]) {
            return #err("Invalid Magic Number");
        };

        let recursive_types_map = Map.new<Nat, CandidType>();

        if (not is_types_set) {
            // extract types from blob
            let total_compound_types = decode_leb128(bytes, state);
            let compound_types = extract_compound_types(bytes, state, total_compound_types, record_key_map);
            candid_types := build_types(bytes, state, compound_types, recursive_types_map);

        } else {
            // types are set but 'blob_contains_only_values' is not set,
            // then skip type section and locate start of values section
            let total_compound_types = decode_leb128(bytes, state);
            skip_compound_types(bytes, state, total_compound_types);
            skip_types(bytes, state);

        };

        let renaming_map = Map.fromIter<Text, Text>(options.renameKeys.vals(), Map.thash);

        // extract values with Candid variant Types
        decode_candid_values(bytes, candid_types, state, options, renaming_map, recursive_types_map);
    };

    let C = {
        BYTES_INDEX = 0;
    };

    // https://en.wikipedia.org/wiki/LEB128
    // func decode_leb128(bytes : Blob, state : [var Nat]) : Nat {
    //     var n64 : Nat64 = 0;
    //     var shift : Nat64 = 0;

    //     var num : Nat = 0;

    //     label decoding_leb loop {
    //         let byte = read(bytes, state);

    //         n64 |= (Nat64.fromNat(Nat8.toNat(byte & 0x7f)) << shift);

    //         shift += 7;

    //         if (shift % 63 == 0) {
    //             if (num != 0) num := num * (2 ** 63);
    //             num += Nat64.toNat(n64);

    //             // n64 := 0;
    //         };

    //         if (byte & 0x80 == 0) break decoding_leb;

    //     };

    //     let num2 = Nat64.toNat(n64);
    //     // Debug.print("(num, num2): " # debug_show (num, num2));
    //     num2;

    // };
    let nat64_bound = 18_446_744_073_709_551_616;
    // func decode_leb128(bytes : Blob, state : [var Nat]) : Nat {
    //     var n64 : Nat64 = 0;
    //     var shift : Nat64 = 0;
    //     var shifted : Nat = 0;

    //     var num : Nat = 0;

    //     label decoding_leb loop {
    //         let byte = read(bytes, state);

    //         n64 |= (Nat64.fromNat(Nat8.toNat(byte & 0x7f)) << shift);

    //         shift += 7;

    //         if (shift % 63 == 0) {
    //             // Debug.print("shift: " # debug_show (shift));
    //             num += Nat64.toNat(n64) * (2 ** shifted);

    //             shifted += Nat64.toNat(shift);
    //             shift := 0;

    //             n64 := 0;
    //         };

    //         if (byte & 0x80 == 0) {
    //             if (num > nat64_bound) {
    //                 num += Nat64.toNat(n64) * (2 ** shifted);
    //             } else {
    //                 num := Nat64.toNat(n64);
    //             };

    //             break decoding_leb;

    //         };

    //     };

    //     // let num2 = Nat64.toNat(n64);
    //     // Debug.print("(num, num2): " # debug_show (num, num2));
    //     num;

    // };

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

    public func decode_candid_values(
        bytes : Blob,
        candid_types : [CandidType],
        state : [var Nat],
        options : T.Options,
        renaming_map : Map<Text, Text>,
        recursive_map : Map<Nat, CandidType>,
    ) : Result<[Candid], Text> {
        var error : ?Text = null;

        let candid_values = Array.tabulate(
            candid_types.size(),
            func(i : Nat) : Candid {
                switch (decode_value(bytes, state, options, renaming_map, recursive_map, candid_types[i])) {
                    case (#ok(candid_value)) candid_value;
                    case (#err(msg)) {
                        error := ?msg;
                        #Empty;
                    };
                };
            },
        );

        switch (error) {
            case (?msg) return #err(msg);
            case (null) {};
        };

        #ok(candid_values);
    };

    func decode_value(
        bytes : Blob,
        state : [var Nat],
        options : T.Options,
        renaming_map : Map<Text, Text>,
        recursive_map : Map<Nat, CandidType>,
        candid_type : CandidType,
    ) : Result<Candid, Text> {
        let iter = createByteIterator(bytes, state);
        decode_value_from_iter(iter, options, renaming_map, recursive_map, candid_type);
    };

    func decode_value_from_iter(
        iter : Iter.Iter<Nat8>,
        options : T.Options,
        renaming_map : Map<Text, Text>,
        recursive_map : Map<Nat, CandidType>,
        candid_type : CandidType,
    ) : Result<Candid, Text> {
        // Debug.print("Decoding candid type: " # debug_show (candid_type));

        let value : Candid = switch (candid_type) {
            case (#Nat) #Nat(decode_leb128_from_iter(iter));
            case (#Nat8) #Nat8(read_from_iter(iter));
            case (#Nat16) #Nat16(ByteUtils.LE.toNat16(iter));
            case (#Nat32) #Nat32(ByteUtils.LE.toNat32(iter));
            case (#Nat64) #Nat64(ByteUtils.LE.toNat64(iter));

            case (#Int) #Int(decode_signed_leb_64_from_iter(iter));
            case (#Int8) #Int8(Int8.fromNat8(read_from_iter(iter)));
            case (#Int16) #Int16(ByteUtils.LE.toInt16(iter));
            case (#Int32) #Int32(ByteUtils.LE.toInt32(iter));
            case (#Int64) #Int64(ByteUtils.LE.toInt64(iter));
            case (#Float) #Float(ByteUtils.LE.toFloat(iter));

            case (#Bool) {
                let byte = read_from_iter(iter);
                let b = if (byte == 0) false else true;
                #Bool(b);
            };
            case (#Null) #Null;
            case (#Empty) #Empty;
            case (#Text) {
                let size = decode_leb128_from_iter(iter);
                let text_bytes = Array.tabulate<Nat8>(
                    size,
                    func(_ : Nat) : Nat8 {
                        read_from_iter(iter);
                    },
                );

                let blob = Blob.fromArray(text_bytes);
                let text = switch (Text.decodeUtf8(blob)) {
                    case (?t) t;
                    case (null) return #err("Failed to decode utf8 text");
                };

                #Text(text);
            };
            case (#Principal) {
                assert read_from_iter(iter) == 0x01; // transparency state. opaque not supported yet.
                let size = decode_leb128_from_iter(iter);

                let principal_bytes = Array.tabulate<Nat8>(
                    size,
                    func(_ : Nat) : Nat8 {
                        read_from_iter(iter);
                    },
                );

                let blob = Blob.fromArray(principal_bytes);
                let p = Principal.fromBlob(blob);

                #Principal(p);
            };

            // ====================== Compound Types =======================

            case (#Option(opt_type)) {
                let is_null = read_from_iter(iter) == 0;

                if (is_null) return #ok(#Null);

                let nested_value = switch (decode_value_from_iter(iter, options, renaming_map, recursive_map, opt_type)) {
                    case (#ok(value)) value;
                    case (#err(err_msg)) return #err(err_msg);
                };

                #Option(nested_value);

            };

            case (#Array(#Nat8)) {
                let size = decode_leb128_from_iter(iter);
                var error : ?Text = null;

                let values = Array.tabulate(
                    size,
                    func(_ : Nat) : Nat8 {
                        switch (decode_value_from_iter(iter, options, renaming_map, recursive_map, #Nat8)) {
                            case (#ok(#Nat8(value))) value;
                            case (#ok(unexpected_type)) {
                                error := ?("Expected #Nat8 value in blob type, instead got " # debug_show (unexpected_type));
                                0;
                            };
                            case (#err(err_msg)) {
                                error := ?err_msg;
                                0;
                            };
                        };
                    },
                );

                switch (error) {
                    case (?msg) return #err(msg);
                    case (null) {};
                };

                let blob = Blob.fromArray(values);

                #Blob(blob);
            };
            case (#Blob(_)) {
                return decode_value_from_iter(iter, options, renaming_map, recursive_map, #Array(#Nat8));
            };

            case (#Array(arr_type)) {
                let size = decode_leb128_from_iter(iter);
                var error : ?Text = null;
                let values = Array.tabulate(
                    size,
                    func(_ : Nat) : Candid {
                        switch (decode_value_from_iter(iter, options, renaming_map, recursive_map, arr_type)) {
                            case (#ok(value)) value;
                            case (#err(err_msg)) {
                                error := ?err_msg;
                                #Empty;
                            };
                        };
                    },
                );

                switch (error) {
                    case (?msg) return #err(msg);
                    case (null) {};
                };

                #Array(values);

            };

            case (#Record(record_types)) {
                var error : ?Text = null;

                var is_tuple = true;
                let n = record_types.size();
                var sum_of_n : Int = n;

                let record_entries = Array.tabulate<(Text, Candid)>(
                    record_types.size(),
                    func(i : Nat) : (Text, Candid) {
                        let record_key = record_types[i].0;
                        if (Utils.text_is_number(record_key)) {
                            sum_of_n -= Utils.text_to_nat(record_key);
                        } else {
                            is_tuple := false;
                        };

                        let record_type = record_types[i].1;

                        let value = switch (decode_value_from_iter(iter, options, renaming_map, recursive_map, record_type)) {
                            case (#ok(value)) value;
                            case (#err(msg)) {
                                error := ?(msg);
                                #Empty;
                            };
                        };

                        (get_renamed_key(renaming_map, record_key), value);
                    },
                );

                is_tuple := is_tuple and sum_of_n == 0;

                switch (error) {
                    case (?msg) return #err(msg);
                    case (null) {};
                };

                if (is_tuple and record_entries.size() > 0) {
                    #Tuple(Array.map<(Text, Candid), Candid>(record_entries, func((_, v) : (Any, Candid)) : Candid = v));
                } else if (options.use_icrc_3_value_type) {
                    #Map(record_entries);
                } else {
                    #Record(record_entries);
                };
            };
            case (#Tuple(tuple_types)) return decode_value_from_iter(
                iter,
                options,
                renaming_map,
                recursive_map,
                #Record(Array.tabulate<(Text, CandidType)>(tuple_types.size(), func(i : Nat) : (Text, CandidType) = (debug_show (i), tuple_types[i]))),
            );
            case (#Variant(variant_types)) {
                let variant_index = decode_leb128_from_iter(iter);

                let variant_key = variant_types[variant_index].0;
                let variant_type = variant_types[variant_index].1;

                var error : ?Text = null;

                let value = switch (decode_value_from_iter(iter, options, renaming_map, recursive_map, variant_type)) {
                    case (#ok(value)) value;
                    case (#err(msg)) {
                        error := ?(msg);
                        #Empty;
                    };
                };

                #Variant(get_renamed_key(renaming_map, variant_key), value);
            };
            case (#Recursive(pos)) {
                let recursive_type = switch (Map.get(recursive_map, nhash, pos)) {
                    case (?recursive_type) recursive_type;
                    case (_) Debug.trap("Recursive type not found");
                };

                return decode_value_from_iter(iter, options, renaming_map, recursive_map, recursive_type);
            };

            case (val) Debug.trap(debug_show (val) # " decoding is not supported");
        };

        #ok(value);
    };

    func get_renamed_key(renaming_map : Map<Text, Text>, key : Text) : Text {
        Option.get(
            Map.get(renaming_map, Map.thash, key),
            key,
        );
    };

    func formatVariantKey(key : Text) : Text {
        let opt = Text.stripStart(key, #text("#"));
        switch (opt) {
            case (?stripped_text) stripped_text;
            case (null) key;
        };
    };

};
