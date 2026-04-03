Filename: `[Section]/[Function].Test.mo`

```motoko
import Debug "mo:base@0.16/Debug";
import Iter "mo:base@0.16/Iter";

import ActorSpec "../utils/ActorSpec";
import Algo "../../src";
// import [FnName] "../../src/[section]/[FnName]";

let {
    assertTrue; assertFalse; assertAllTrue; 
    describe; it; skip; pending; run
} = ActorSpec;

let success = run([
    describe(" (Function Name) ", [
        it("(test name)", do {
            
            // ...
        }),
    ])
]);

if(success == false){
  Runtime.trap("\1b[46;41mTests failed\1b[0m");
}else{
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};

```