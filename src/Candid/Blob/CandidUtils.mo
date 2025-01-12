import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Order "mo:base/Order";

import Itertools "mo:itertools/Iter";
import Map "mo:map/Map";
import { hashName = hash_record_key } "mo:candid/Tag";

import T "../Types";
import TrieMap "mo:base/TrieMap";
import Utils "../../Utils";

module {

    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<A, B> = Result.Result<A, B>;
    type Buffer<A> = Buffer.Buffer<A>;
    type Iter<A> = Iter.Iter<A>;
    type Hash = Nat32;
    type Map<K, V> = Map.Map<K, V>;
    type Order = Order.Order;

    type Candid = T.Candid;
    type CandidType = T.CandidType;
    type KeyValuePair = T.KeyValuePair;

    let { thash } = Map;

    public func cmp_fields(a : (Text, Any), b : (Text, Any)) : Order {

        let hash_a = hash_record_key(a.0);
        let hash_b = hash_record_key(b.0);

        Nat32.compare(hash_a, hash_b);
    };

    public func cmp_nat_fields(a : (Text, Any), b : (Text, Any)) : Order {

        let n1 = Utils.text_to_nat(a.0);
        let n2 = Utils.text_to_nat(b.0);

        Nat.compare(n1, n2);
    };

    public func is_record_tuple(record_fields : [(Text, Any)]) : Bool {
        Itertools.all(
            record_fields.vals(),
            func(field : (Text, Any)) : Bool {
                Utils.text_is_number(field.0);
            },
        );
    };

    public func sort_candid_type(candid_type : CandidType) : CandidType {
        switch (candid_type) {
            case (#Record(fields)) {
                let is_tuple = Itertools.all(
                    fields.vals(),
                    func(field : (Text, Any)) : Bool {
                        Utils.text_is_number(field.0);
                    },
                );

                let sorted_fields = if (is_tuple) {
                    (Array.sort(fields, cmp_nat_fields));
                } else {
                    (Array.sort(fields, cmp_fields));
                };

                let sorted_nested_fields = Array.map<(Text, CandidType), (Text, CandidType)>(
                    sorted_fields,
                    func(field : (Text, CandidType)) : (Text, CandidType) {
                        (field.0, sort_candid_type(field.1));
                    },
                );

                #Record(sorted_nested_fields);
            };
            case (#Variant(fields)) {
                let is_tuple = Itertools.all(
                    fields.vals(),
                    func(field : (Text, CandidType)) : Bool {
                        Utils.text_is_number(field.0);
                    },
                );

                let sorted_fields = if (is_tuple) {
                    (Array.sort(fields, cmp_nat_fields));
                } else {
                    (Array.sort(fields, cmp_fields));
                };

                let sorted_nested_fields = Array.map<(Text, CandidType), (Text, CandidType)>(
                    sorted_fields,
                    func(field : (Text, CandidType)) : (Text, CandidType) {
                        (field.0, sort_candid_type(field.1));
                    },
                );

                #Variant(sorted_nested_fields);
            };
            case (#Array(arr_type)) #Array(sort_candid_type(arr_type));
            case (#Option(opt_type)) #Option(sort_candid_type(opt_type));
            case (#Tuple(tuple_types)) #Tuple(Array.map(tuple_types, sort_candid_type));
            case (other_types) other_types;
        };
    };

    func tuple_type_to_record(tuple_types : [CandidType], mapper : (CandidType) -> CandidType) : [(Text, CandidType)] {
        Array.tabulate<(Text, CandidType)>(
            tuple_types.size(),
            func(i : Nat) : (Text, CandidType) {
                let key = Text.replace(debug_show (i), #char('_'), "");
                (key, mapper(tuple_types[i]));
            },
        );
    };

    /// Sorts fields by their hash value and renames changed fields
    ///
    /// Also resolves aliases by renaming them to their canonical name,
    /// for example #Blob to #Array(#Nat8)
    public func format_candid_type(candid_type : CandidType, renaming_map : Map<Text, Text>) : CandidType {
        switch (candid_type) {
            case (#Record(fields) or #Map(fields)) {

                var is_tuple = true;

                let renamed_fields = Array.tabulate<(Text, CandidType)>(
                    fields.size(),
                    func(i : Nat) : (Text, CandidType) {
                        let field_key = fields[i].0;
                        let field_value = fields[i].1;

                        let new_key = switch (Map.get(renaming_map, thash, field_key)) {
                            case (?new_key) new_key;
                            case (_) field_key;
                        };

                        is_tuple := is_tuple and Utils.text_is_number(new_key);

                        (new_key, format_candid_type(field_value, renaming_map));
                    },
                );

                let sorted_fields = if (is_tuple) {
                    (Array.sort(renamed_fields, cmp_nat_fields));
                } else {
                    (Array.sort(renamed_fields, cmp_fields));
                };

                #Record(sorted_fields);
            };
            case (#Variant(fields)) {
                var is_tuple = true;

                let renamed_fields = Array.tabulate<(Text, CandidType)>(
                    fields.size(),
                    func(i : Nat) : (Text, CandidType) {
                        let field_key = fields[i].0;
                        let field_value = fields[i].1;

                        let new_key = switch (Map.get(renaming_map, thash, field_key)) {
                            case (?new_key) new_key;
                            case (_) field_key;
                        };

                        is_tuple := is_tuple and Utils.text_is_number(new_key);

                        (new_key, format_candid_type(field_value, renaming_map));
                    },
                );

                let sorted_fields = if (is_tuple) {
                    (Array.sort(renamed_fields, cmp_nat_fields));
                } else {
                    (Array.sort(renamed_fields, cmp_fields));
                };

                #Variant(sorted_fields);
            };
            case (#Blob) #Array(#Nat8);
            case (#Array(arr_type)) #Array(format_candid_type(arr_type, renaming_map));
            case (#Option(opt_type)) #Option(format_candid_type(opt_type, renaming_map));
            case (#Tuple(tuple_types)) #Record(
                tuple_type_to_record(
                    tuple_types,
                    func(candid_type : CandidType) : CandidType = format_candid_type(candid_type, renaming_map),
                )
            );
            case (other_types) other_types;
        };
    };

    public func sort_candid_value(candid_value : Candid) : Candid {
        switch (candid_value) {
            case (#Record(fields)) {
                let is_tuple = Itertools.all(
                    fields.vals(),
                    func(field : (Text, Any)) : Bool {
                        Utils.text_is_number(field.0);
                    },
                );

                if (is_tuple) {
                    #Record(Array.sort(fields, cmp_nat_fields));
                } else {
                    #Record(Array.sort(fields, cmp_fields));
                };
            };
            case (other_values) other_values;
        };
    };

    public func RecordType(records : [(Text, CandidType)]) : CandidType {
        #Record(Array.sort(records, cmp_fields));
    };

    public func RecordValue(records : [(Text, Candid)]) : Candid {
        #Record(Array.sort(records, cmp_fields));
    };
};
