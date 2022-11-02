import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

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

let success = run([
    describe(
        "Candid",
        [
            it(
                "encode()",
                do {
                    let motoko = { name = "Tomi" };
                    let blob = to_candid (motoko);
                    let candid = Candid.encode(blob, ["name"]);

                    candid == #Record([("name", #Text("Tomi"))]);
                },
            ),

            it(
                "decode()",
                do {
                    let candid = #Record([("name", #Text("Tomi"))]);
                    type User = {
                        name : Text;
                    };

                    let blob = Candid.decode(candid);
                    let user : ?User = from_candid (blob);

                    user == ?{ name = "Tomi" };
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
