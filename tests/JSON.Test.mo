import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

import JSON "../src/JSON";
import Candid "../src/Candid";

let {
    assertTrue;
    assertFalse;
    assertAllTrue;
    describe;
    it;
    skip;
    pending;
    run;
} = ActorSpec;

type User = {
    name : Text;
    id : ?Int;
};

let success = run([
    describe(
        "JSON",
        [
            it(
                "fromText()",
                do {
                    let text = "{\"name\": \"Tomi\", \"id\": 32}";
                    let blob = JSON.fromText(text);
                    let user : ?User = from_candid (blob);

                    user == ?{ name = "Tomi"; id = ?32 };
                },
            ),
            it(
                "decode()",
                do {
                    let user = { name = "Tomi"; id = null };
                    let blob = to_candid (user);
                    let jsonText = JSON.toText(blob, ["name", "id"]);

                    jsonText == "{\"id\": null, \"name\": \"Tomi\"}";
                },
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
