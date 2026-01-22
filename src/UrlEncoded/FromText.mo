import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Char "mo:core/Char";
import Debug "mo:core/Debug";
import Result "mo:core/Result";
import PureMap "mo:core/pure/Map";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Option "mo:core/Option";

import Itertools "mo:itertools@0.2.2/Iter";

import Candid "../Candid";
import T "../Candid/Types";
import { parseValue } "./Parser";
import U "../Utils";
import Utils "../Utils";

module {
    let { subText; Buffer } = U;

    type Candid = Candid.Candid;

    type Buffer<A> = Utils.Buffer.Buffer<A>;
    type Iter<A> = Iter.Iter<A>;
    type Map<K, V> = PureMap.Map<K, V>;
    type Result<A, B> = Result.Result<A, B>;

    type TextOrMap = {
        #text : Text;
        #map : Map<Text, TextOrMap>;
    };

    type NestedMap = Map<Text, TextOrMap>;

    func newMap() : NestedMap = PureMap.empty<Text, TextOrMap>();

    /// Converts a Url-Encoded Text to a serialized Candid Record
    public func fromText(text : Text, options : ?T.Options) : Result<Blob, Text> {
        let res = toCandid(text, Option.get(options, T.defaultOptions));
        let #ok(candid) = res else return Utils.send_error(res);

        Candid.encodeOne(candid, options);
    };

    /// Converts a Url-Encoded Text to a Candid Record
    public func toCandid(text : Text, options : T.Options) : Result<Candid, Text> {
        let map_res = entriesToMap(text, options);

        let #ok(map) = map_res else return Utils.send_error(map_res);

        mapToCandid(map, options);
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
    // Into a nested Map
    // --------------------------------------------------
    // Map {
    //     'users' => Map {
    //         '0' => Map {
    //             'name' => 'peter',
    //             'age' => '20',
    //         },
    //         '1' => Map {
    //             'name' => 'john',
    //             'age' => '30',
    //         },
    //     },
    //     'settings' => Map {
    //         'theme' => 'dark',
    //         'language' => 'en',
    //     },
    // }
    // --------------------------------------------------
    func entriesToMap(text : Text, options : T.Options) : Result<NestedMap, Text> {
        let entries : [Text] = Array.sort(
            Iter.toArray(Text.split(text, #char '&')),
            Text.compare,
        );

        var map : NestedMap = newMap();

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
                )
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

                    let res = insert(map, first_field, other_fields, value);
                    switch (res) {
                        case (#ok(newMap)) { map := newMap };
                        case (#err(msg)) return #err(msg);
                    };
                };
                case (_) {
                    let res = insert(map, key, Itertools.empty(), value);
                    switch (res) {
                        case (#ok(newMap)) { map := newMap };
                        case (#err(msg)) return #err(msg);
                    };
                };
            };
        };

        #ok(map);
    };

    // Convert from a nested Map
    // --------------------------------------------------
    // Map {
    //     'users' => Map {
    //         '0' => Map {
    //             'name' => 'peter',
    //             'age' => '20',
    //         },
    //         '1' => Map {
    //             'name' => 'john',
    //             'age' => '30',
    //         },
    //     },
    //     'settings' => Map {
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

    func mapToCandid(map : NestedMap, options : T.Options) : Result<Candid, Text> {
        var i = 0;
        let isArray = Itertools.all(
            Iter.sort(PureMap.keys(map), Text.compare),
            func(key : Text) : Bool {
                let res = key == Nat.toText(i);
                i += 1;
                res;
            },
        );

        if (isArray) {
            let buffer = Buffer.Buffer<Candid>(PureMap.size(map));

            for (i in Itertools.range(0, PureMap.size(map))) {

                switch (PureMap.get(map, Text.compare, Nat.toText(i))) {
                    case (?(#text(text))) {
                        let candid = parseValue(text);
                        buffer.add(candid);
                    };
                    case (?(#map(nestedMap))) {
                        let res = mapToCandid(nestedMap, options);
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
        if (PureMap.size(map) == 1) {
            let (variant_key, value) = switch (PureMap.entries(map).next()) {
                case (?(k, v)) { (k, v) };
                case (_) { Debug.trap("Variant might be improperly formatted") };
            };

            let isVariant = Text.startsWith(variant_key, #text "#");

            if (isVariant) {
                let key = U.stripStart(variant_key, #text "#");

                let value_res = switch (value) {
                    case (#text(text)) #ok(parseValue(text));
                    case (#map(nestedMap)) mapToCandid(nestedMap, options);
                };

                let #ok(val) = value_res else return Utils.send_error(value_res);

                return #ok(#Variant((key, val)));
            };
        };

        let buffer = Buffer.Buffer<(Text, Candid)>(PureMap.size(map));

        for ((key, field) in PureMap.entries(map)) {
            switch (field) {
                case (#text(text)) {
                    let candid = parseValue(text);
                    buffer.add((key, candid));
                };
                case (#map(nestedMap)) {
                    let res = mapToCandid(nestedMap, options);
                    let #ok(candid) = res else return Utils.send_error(res);
                    buffer.add((key, candid));
                };
            };
        };

        let records = Buffer.toArray(buffer);

        // let map_or_record = if ()
        #ok(#Record(records));
    };

    // Inserts a key value pair from UrlSearchParams into a nested Map
    func insert(map : NestedMap, field : Text, fields_iter : Iter<Text>, value : Text) : Result<NestedMap, Text> {
        let next_field = switch (fields_iter.next()) {
            case (?_field) _field;
            case (_) {
                let newMap = PureMap.add(map, Text.compare, field, #text(value));
                return #ok(newMap);
            };
        };

        let nestedMap = switch (PureMap.get(map, Text.compare, field)) {
            case (?val) {
                switch (val) {
                    case (#text(prevValue)) {
                        return #err("field name '" # field # "' cannot have multiple values: '" # prevValue # "' and '" # value # "'");
                    };
                    case (#map(nestedMap)) nestedMap;
                };
            };
            case (_) {
                newMap();
            };
        };

        let updatedNestedRes = insert(nestedMap, next_field, fields_iter, value);
        switch (updatedNestedRes) {
            case (#ok(updatedNested)) {
                let newMap = PureMap.add(map, Text.compare, field, #map(updatedNested));
                #ok(newMap);
            };
            case (#err(msg)) #err(msg);
        };
    };
};
