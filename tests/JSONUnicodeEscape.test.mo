// @testmode wasi
import Debug "mo:core@2.4/Debug";
import Text "mo:core@2.4/Text";

import { test; suite } "mo:test";

import { JSON } "../src";

suite(
    "JSON \\u escape support",
    func() {
        test(
            "BMP codepoint \\u00e9 (é) parses",
            func() {
                let r = JSON.toCandid("\"caf\\u00e9\"");
                switch (r) {
                    case (#ok(#Text(s))) {
                        Debug.print("decoded: " # s);
                        assert s == "café";
                    };
                    case (#ok(other)) {
                        Debug.print("wrong shape: " # debug_show(other));
                        assert false;
                    };
                    case (#err(msg)) {
                        Debug.print("err: " # msg);
                        assert false;
                    };
                };
            },
        );

        test(
            "non-BMP surrogate pair \\uD83C\\uDF93 (graduation cap) parses",
            func() {
                let r = JSON.toCandid("\"\\uD83C\\uDF93\"");
                switch (r) {
                    case (#ok(#Text(s))) {
                        Debug.print("decoded: " # s # " (size " # debug_show(s.size()) # " chars)");
                        // s should be the single 🎓 character (one Char)
                        assert s.size() == 1;
                    };
                    case (#ok(other)) {
                        Debug.print("wrong shape: " # debug_show(other));
                        assert false;
                    };
                    case (#err(msg)) {
                        Debug.print("err: " # msg);
                        assert false;
                    };
                };
            },
        );

        test(
            "Twitter-like response with surrogate-pair emoji parses",
            func() {
                let body = "{\"data\":{\"text\":\"hello \\uD83C\\uDF93 world\",\"id\":\"1234\",\"edit_history_tweet_ids\":[\"1234\"]}}";
                switch (JSON.toCandid(body)) {
                    case (#ok(_)) {};
                    case (#err(msg)) {
                        Debug.print("err: " # msg);
                        assert false;
                    };
                };
            },
        );
    },
);
