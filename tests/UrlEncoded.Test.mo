import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

import ActorSpec "./utils/ActorSpec";

import UrlEncoded "../src/UrlEncoded";

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
    msg : Text;
};

let success = run([
    describe(
        "UrlEncoded Pairs",
        [
            describe(
                "fromText to motoko",
                [
                    it(
                        "single record",
                        do {

                            let blob = UrlEncoded.fromText("msg=Hello World&name=John");

                            let res : ?User = from_candid (blob);

                            assertTrue(
                                res == ?{
                                    name = "John";
                                    msg = "Hello World";
                                },
                            );
                        },
                    ),
                    it(
                        "record with array",
                        do {
                            let blob = UrlEncoded.fromText(
                                "users[0][name]=John&users[0][msg]=Hello World&users[1][name]=Jane&users[1][msg]=testing",
                            );

                            let res : ?{ users : [User] } = from_candid (blob);
                            Debug.print(debug_show res);
                            assertTrue(
                                res == ?{
                                    users = [
                                        {
                                            name = "John";
                                            msg = "Hello World";
                                        },
                                        {
                                            name = "Jane";
                                            msg = "testing";
                                        },
                                    ];
                                },
                            );
                        },
                    ),
                ],
            ),
            describe(
                "motoko toText",
                [
                    it(
                        "single record",
                        do {

                            let info : User = {
                                msg = "Hello World";
                                name = "John";
                            };

                            let blob = to_candid (info);
                            let text = UrlEncoded.toText(blob, ["name", "msg"]);

                            assertTrue(text == "msg=Hello World&name=John");
                        },
                    ),
                    it(
                        "record with array",
                        do {
                            let users = [
                                {
                                    name = "John";
                                    msg = "Hello World";
                                },
                                {
                                    name = "Jane";
                                    msg = "testing";
                                },
                            ];

                            let blob = to_candid ({ users });

                            let text = UrlEncoded.toText(blob, ["users", "name", "msg"]);

                            assertTrue(
                                text == "users[0][msg]=Hello World&users[0][name]=John&users[1][msg]=testing&users[1][name]=Jane",
                            );
                        },
                    ),
                ],
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
