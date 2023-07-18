import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Float "mo:base/Float";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";

import itertools "mo:itertools/Iter";

import Candid "../Candid";
import CandidTypes "../Candid/Types";
import { parseValue } "./Parser";
import U "../Utils";

module {
    let { subText } = U;

    type Candid = Candid.Candid;

    type Buffer<A> = Buffer.Buffer<A>;
    type Iter<A> = Iter.Iter<A>;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    type TextOrTrieMap = {
        #text : Text;
        #triemap : TrieMap<Text, TextOrTrieMap>;
    };

    type NestedTrieMap = TrieMap<Text, TextOrTrieMap>;

    func newMap() : NestedTrieMap = TrieMap.TrieMap(Text.equal, Text.hash);

    /// Converts a Url-Encoded Text to a serialized Candid Record
    public func fromText(text : Text, options: ?CandidTypes.Options) : Blob {
        let candid = toCandid(text);
        Candid.encodeOne(candid, options);
    };

    /// Converts a Url-Encoded Text to a Candid Record
    public func toCandid(text : Text) : Candid {
        let nestedTriemap = entriesToTrieMap(text);
        trieMapToCandid(nestedTriemap);
    };

    // Converting entries from UrlSearchParams
    // --------------------------------------------------
    // 'users[0][name]=peter'
    // 'users[0][age]=20'
    // 'users[1][name]=john'
    // 'users[1][age]=30'
    //
    // 'settings[theme]=dark'
    // 'settings[language]=en'
    //
    // --------------------------------------------------
    // Into a nested TrieMap
    // --------------------------------------------------
    // TrieMap {
    //     'users' => TrieMap {
    //         '0' => TrieMap {
    //             'name' => 'peter',
    //             'age' => '20',
    //         },
    //         '1' => TrieMap {
    //             'name' => 'john',
    //             'age' => '30',
    //         },
    //     },
    //     'settings' => TrieMap {
    //         'theme' => 'dark',
    //         'language' => 'en',
    //     },
    // }
    // --------------------------------------------------
    func entriesToTrieMap(text : Text) : NestedTrieMap {
        let entries : [Text] = Array.sort(
            Iter.toArray(Text.split(text, #char '&')),
            Text.compare,
        );

        let triemap : NestedTrieMap = newMap();

        for (entry in entries.vals()) {
            let entry_iter = Text.split(entry, #char '=');
            let key = switch (entry_iter.next()) {
                case (?_key) _key;
                case (_) Debug.trap("Missing key: improper formatting of key-value pair in '" # entry # "'");
            };

            let value = switch (entry_iter.next()) {
                case (?val) val;
                case (_) Debug.trap("Missing value: improper formatting of key value pair in '" # entry # "'");
            };

            switch (
                itertools.findIndex(
                    key.chars(),
                    func(c : Char) : Bool = c == '[',
                ),
            ) {
                case (?index) {
                    let first_field = subText(key, 0, index);

                    let stripped_key = switch (Text.stripEnd(key, #text "]")) {
                        case (?stripped_key) stripped_key;
                        case (_) Debug.trap("Improper formatting of key value pair in '" # entry # "' -> Missing closing bracket ']'");
                    };

                    if (first_field.size() == 0) {
                        return Debug.trap("Missing field name between brackets '[]' in '" # entry # "'");
                    };

                    let other_fields = Text.split(
                        subText(stripped_key, index + 1, stripped_key.size()),
                        #text "][",
                    );

                    insert(triemap, first_field, other_fields, value);
                };
                case (_) {
                    insert(triemap, key, itertools.empty(), value);
                };
            };
        };

        triemap;
    };

    // Convert from a nested TrieMap
    // --------------------------------------------------
    // TrieMap {
    //     'users' => TrieMap {
    //         '0' => TrieMap {
    //             'name' => 'peter',
    //             'age' => '20',
    //         },
    //         '1' => TrieMap {
    //             'name' => 'john',
    //             'age' => '30',
    //         },
    //     },
    //     'settings' => TrieMap {
    //         'theme' => 'dark',
    //         'language' => 'en',
    //     },
    // }
    // --------------------------------------------------
    // Into a Candid Record
    // --------------------------------------------------
    // {
    //     users : [
    //         {
    //             name : "peter",
    //             age : 20,
    //         },
    //         {
    //             name : "john",
    //             age : 30,
    //         },
    //     ],
    //     settings : {
    //         theme : "dark",
    //         language : "en",
    //     },
    // }
    // --------------------------------------------------

    func trieMapToCandid(triemap : NestedTrieMap) : Candid {
        var i = 0;
        let isArray = itertools.all(
            Iter.sort(triemap.keys(), Text.compare),
            func(key : Text) : Bool {
                let res = key == Nat.toText(i);
                i += 1;
                res;
            },
        );

        if (isArray) {
            let array = Array.tabulate<Candid>(
                triemap.size(),
                func(i : Nat) {
                    switch (triemap.get(Nat.toText(i))) {
                        case (?(#text(text))) parseValue(text);
                        case (?(#triemap(map))) trieMapToCandid(map);
                        case (_) Prelude.unreachable();
                    };
                },
            );

            return #Array(array);
        };

        // check if single value is a variant
        if (triemap.size() == 1) {
            let (variant_key, value) = switch (triemap.entries().next()) {
                case (?(k, v))(k, v);
                case (_) Prelude.unreachable();
            };

            let isVariant = Text.startsWith(variant_key, #text "#");

            if (isVariant) {
                let key = U.stripStart(variant_key, #text "#");

                let val = switch (value) {
                    case (#text(text)) parseValue(text);
                    case (#triemap(map)) trieMapToCandid(map);
                };

                return #Variant((key, val));
            };
        };

        let records_iter = Iter.map<(Text, TextOrTrieMap), (Text, Candid)>(
            triemap.entries(),
            func((key, value) : (Text, TextOrTrieMap)) : (Text, Candid) {
                switch (value) {
                    case (#text(text)) {
                        (key, parseValue(text));
                    };
                    case (#triemap(map)) {
                        (key, trieMapToCandid(map));
                    };
                };
            },
        );

        let records = Iter.toArray(records_iter);

        #Record(records);
    };

    // Inserts a key value pair from UrlSearchParams into a nested TrieMap
    func insert(map : NestedTrieMap, field : Text, fields_iter : Iter<Text>, value : Text) {
        let next_field = switch (fields_iter.next()) {
            case (?_field) _field;
            case (_) {
                map.put(field, #text(value));
                return;
            };
        };

        let nestedTriemap = switch (map.get(field)) {
            case (?val) {
                switch (val) {
                    case (#text(prevValue)) {
                        Debug.trap("field name '" # field # "' cannot have multiple values: '" # prevValue # "' and '" # value # "'");
                    };
                    case (#triemap(nestedTriemap)) nestedTriemap;
                };
            };
            case (_) {
                let nestedTriemap = newMap();
                map.put(field, #triemap(nestedTriemap));
                nestedTriemap;
            };
        };

        insert(nestedTriemap, next_field, fields_iter, value);
    };
};
