// @testmode wasi
import Map "mo:core@2.4/pure/Map";
import Text "mo:core@2.4/Text";
import Debug "mo:core@2.4/Debug";

import { test; suite } "mo:test";

import { JSON; Candid } "../src";

// Regression for the Decoder._build_compound_type cycle-detection bug:
// when a recursive type (Map<K,V> = self-referential RBT) is referenced
// from two sibling fields (e.g. left + right of a tree node), the second
// reference used to fall through `is_recursive_set` membership and
// re-descend into the cyclic body, blowing the Wasm stack.
//
// The trigger reproduces `to_candid(req)` on OpenAI's CreateChatCompletionRequest,
// which carries `metadata : ?Map<Text, Text>` and `logit_bias : ?Map<Text, Int>`.

type RequestLike = {
    metadata : ?Map.Map<Text, Text>;
    logit_bias : ?Map.Map<Text, Int>;
    other : Text;
};

suite(
    "Decoder cycle detection — Map<K, V> in record (regression)",
    func() {
        test(
            "to_candid + JSON.toText round-trips a record containing two ?Map fields without stack overflow",
            func() {
                let req : RequestLike = {
                    metadata = null;
                    logit_bias = null;
                    other = "hello";
                };

                let blob = to_candid (req);

                let result = JSON.toText(
                    blob,
                    ["metadata", "logit_bias", "other"],
                    ?{ Candid.defaultOptions with skip_null_fields = true },
                );

                switch (result) {
                    case (#ok(json)) {
                        Debug.print("ok: " # json);
                        assert Text.contains(json, #text "\"other\"");
                        assert Text.contains(json, #text "\"hello\"");
                    };
                    case (#err(msg)) {
                        Debug.print("err: " # msg);
                        assert false;
                    };
                };
            },
        );

        test(
            "non-empty Map<Text, Text> serialises without re-expanding the recursive node type",
            func() {
                let m = Map.empty<Text, Text>()
                    |> Map.add(_, Text.compare, "k1", "v1")
                    |> Map.add(_, Text.compare, "k2", "v2");

                let req : RequestLike = {
                    metadata = ?m;
                    logit_bias = null;
                    other = "world";
                };

                let blob = to_candid (req);

                let result = JSON.toText(
                    blob,
                    ["metadata", "logit_bias", "other"],
                    ?{ Candid.defaultOptions with skip_null_fields = true },
                );

                switch (result) {
                    case (#ok(json)) {
                        Debug.print("ok: " # json);
                        assert Text.contains(json, #text "\"world\"");
                    };
                    case (#err(msg)) {
                        Debug.print("err: " # msg);
                        assert false;
                    };
                };
            },
        );
    },
);
