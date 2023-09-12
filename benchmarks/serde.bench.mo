import Prim "mo:prim";
import Cycles "mo:base/ExperimentalCycles";
import IC "mo:base/ExperimentalInternetComputer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Serde "../src";

actor {
    type Candid = Serde.Candid;
    let { Candid } = Serde;

    type Permission = {
        #read : [Text];
        #write : [Text];
        #read_all : ();
        #write_all : ();
        #admin : ();
    };

    type User = {
        name : Text;
        age : Nat;
        permission : Permission;
    };

    type Record = {
        group : Text;
        users : ?[User];
    };

    public query func cycles() : async Nat { Cycles.balance()};

    public query func deserialize(n: Nat) : async (Nat64, Nat, Nat, Nat) {
        let init_cycles = Cycles.balance();

        let init_heap = Prim.rts_heap_size();
        let init_memory = Prim.rts_memory_size();

        let calls = IC.countInstructions(
            func() {

                let admin_record_candid : Candid = #Record([
                    ("group", #Text("admins")),
                    ("users", #Option(#Array([#Record([("age", #Nat(32)), ("name", #Text("John")), ("permission", #Variant("admin", #Null))])]))),
                ]);

                let user_record_candid : Candid = #Record([
                    ("group", #Text("users")),
                    ("users", #Option(#Array([#Record([("age", #Nat(28)), ("name", #Text("Ali")), ("permission", #Variant("read_all", #Null))]), #Record([("age", #Nat(40)), ("name", #Text("James")), ("permission", #Variant("write_all", #Null))])]))),
                ]);

                let empty_record_candid : Candid = #Record([
                    ("group", #Text("empty")),
                    ("users", #Option(#Array([]))),
                ]);

                let null_record_candid : Candid = #Record([
                    ("group", #Text("null")),
                    ("users", #Option(#Null)),
                ]);

                let base_record_candid : Candid = #Record([
                    ("group", #Text("base")),
                    ("users", #Option(#Array([#Record([("age", #Nat(32)), ("name", #Text("Henry")), ("permission", #Variant("read", #Array([#Text("posts"), #Text("comments")])))]), #Record([("age", #Nat(32)), ("name", #Text("Steven")), ("permission", #Variant("write", #Array([#Text("posts"), #Text("comments")])))])]))),
                ]);

                let records : Candid = #Array([
                    null_record_candid,
                    empty_record_candid,
                    admin_record_candid,
                    user_record_candid,
                    base_record_candid,
                ]);
                
                for (_ in Iter.range(1, n)){
                    let #ok(blob) = Candid.encodeOne(records, null);
                    let motoko : ?[Record] = from_candid (blob);
                    Debug.print(debug_show (motoko));
                };
            }
        );

        (calls, Prim.rts_heap_size() - init_heap, Prim.rts_memory_size() - init_memory, init_cycles - Cycles.balance())
    };

};
