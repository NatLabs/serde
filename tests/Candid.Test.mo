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

                    Debug.print(debug_show candid);

                    // let deserialised : ?{ name : Text } = from_candid (blob);
                    // Debug.print(debug_show deserialised);
                    // Debug.print(debug_show Candid.decode(blob));

                    // blob == Blob.fromArray([0x44, 0x49, 0x44, 0x4C, 0x01, 0x6C, 0x01, 0xCB, 0xE4, 0xFD, 0xC7, 0x04, 0x71, 0x01, 0x00, 0x04, 0x54, 0x6F, 0x6D, 0x69]);
                    // candid == #Record([("name", #Text("Tomi"))]);
                    true;
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
                    // let user : ?User = from_candid (blob);

                    // user == ?{ name = "Tomi" };
                    true;
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
