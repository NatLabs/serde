import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Option "mo:base/Option";

import Itertools "mo:itertools/Iter";

import Candid "../Candid";
import T "../Candid/Types";
import { parseValue } "./Parser";
import U "../Utils";
import Utils "../Utils";

module {
    let { subText } = U;

    type Candid = Candid.Candid;

    type Buffer<A> = Buffer.Buffer<A>;
    type Iter<A> = Iter.Iter<A>;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<A, B> = Result.Result<A, B>;

    type TextOrTrieMap = {
        #text : Text;
        #triemap : TrieMap<Text, TextOrTrieMap>;
    };

    type NestedTrieMap = TrieMap<Text, TextOrTrieMap>;

    func newMap() : NestedTrieMap = TrieMap.TrieMap(Text.equal, Text.hash);

    /// Converts a Url-Encoded Text to a serialized Candid Record
    public func fromText(text : Text, options: ?T.Options) : Result<Blob, Text> {
        let res = toCandid(text, Option.get(options, T.defaultOptions));
        let #ok(candid) = res else return Utils.send_error(res);

        Candid.encodeOne(candid, options);
    };

    /// Converts a Url-Encoded Text to a Candid Record
    public func toCandid(text : Text, options: T.Options) : Result<Candid, Text> {
        let triemap_res = entriesToTrieMap(text, options);

        let #ok(triemap) = triemap_res else return Utils.send_error(triemap_res);

        trieMapToCandid(triemap, options);
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
    func entriesToTrieMap(text : Text, options: T.Options) : Result<NestedTrieMap, Text> {
        let entries : [Text] = Array.sort(
            Iter.toArray(Text.split(text, #char '&')),
            Text.compare,
        );

        let triemap : NestedTrieMap = newMap();

        for (entry in entries.vals()) {
            let entry_iter = Text.split(entry, #char '=');
            let key = switch (entry_iter.next()) {
                case (?_key) _key;
                case (_) return #err("Missing key: improper formatting of key-value pair in '" # entry # "'");
            };

            let value = switch (entry_iter.next()) {
                case (?val) val;
                case (_) return #err("Missing value: improper formatting of key value pair in '" # entry # "'");
            };

            switch (
                Itertools.findIndex(
                    key.chars(),
                    func(c : Char) : Bool = c == '[',
                ),
            ) {
                case (?index) {
                    let first_field = subText(key, 0, index);

                    let stripped_key = switch (Text.stripEnd(key, #text "]")) {
                        case (?stripped_key) stripped_key;
                        case (_) return #err("Improper formatting of key value pair in '" # entry # "' -> Missing closing bracket ']'");
                    };

                    if (first_field.size() == 0) {
                        return return #err("Missing field name between brackets '[]' in '" # entry # "'");
                    };

                    let other_fields = Text.split(
                        subText(stripped_key, index + 1, stripped_key.size()),
                        #text "][",
                    );

                    let res = insert(triemap, first_field, other_fields, value);
                    let #ok(_) = res else return Utils.send_error(res);
                };
                case (_) {
                    let res = insert(triemap, key, Itertools.empty(), value);
                    let #ok(_) = res else return Utils.send_error(res);
                };
            };
        };

        #ok(triemap);
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

    func trieMapToCandid(triemap : NestedTrieMap, options: T.Options) : Result<Candid, Text> {
        var i = 0;
        let isArray = Itertools.all(
            Iter.sort(triemap.keys(), Text.compare),
            func(key : Text) : Bool {
                let res = key == Nat.toText(i);
                i += 1;
                res;
            },
        );

        if (isArray) {
            let buffer = Buffer.Buffer<Candid>(triemap.size());

            for (i in Itertools.range(0, triemap.size())){

                switch(triemap.get(Nat.toText(i))) {
                    case (?(#text(text))) {
                        let candid = parseValue(text);
                        buffer.add(candid);
                    };
                    case (?(#triemap(map))) {
                        let res = trieMapToCandid(map, options);
                        let #ok(candid) = res else return Utils.send_error(res);
                        buffer.add(candid);
                    };

                    case (_) Debug.trap("Array might be improperly formatted");
                };
            };

            let arr = Buffer.toArray(buffer);

            return #ok(#Array(arr));
        };

        // check if single value is a variant
        if (triemap.size() == 1) {
            let (variant_key, value) = switch (triemap.entries().next()) {
                case (?(k, v)) { (k, v) };
                case (_)       { Debug.trap("Variant might be improperly formatted"); };
            };

            let isVariant = Text.startsWith(variant_key, #text "#");

            if (isVariant) {
                let key = U.stripStart(variant_key, #text "#");

                let value_res = switch (value) {
                    case (#text(text)) #ok(parseValue(text));
                    case (#triemap(map)) trieMapToCandid(map, options);
                };

                let #ok(val) = value_res else return Utils.send_error(value_res);

                return #ok(#Variant((key, val)));
            };
        };

        let buffer = Buffer.Buffer<(Text, Candid)>(triemap.size());

        for ((key, field) in triemap.entries()){
            switch (field){
                case (#text(text)) {
                    let candid = parseValue(text);
                    buffer.add((key, candid));
                };
                case (#triemap(map)) {
                    let res = trieMapToCandid(map, options);
                    let #ok(candid) = res else return Utils.send_error(res);
                    buffer.add((key, candid));
                };
            };
        };

        let records = Buffer.toArray(buffer);

        // let map_or_record = if ()
        #ok(#Record(records));
    };

    // Inserts a key value pair from UrlSearchParams into a nested TrieMap
    func insert(map : NestedTrieMap, field : Text, fields_iter : Iter<Text>, value : Text) : Result<(), Text> {
        let next_field = switch (fields_iter.next()) {
            case (?_field) _field;
            case (_) {
                map.put(field, #text(value));
                return #ok();
            };
        };

        let nestedTriemap = switch (map.get(field)) {
            case (?val) {
                switch (val) {
                    case (#text(prevValue)) {
                        return #err("field name '" # field # "' cannot have multiple values: '" # prevValue # "' and '" # value # "'");
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
