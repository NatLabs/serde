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

    type Benchmark = {
        calls: Nat64;
        heap: Nat;
        memory: Nat;
        cycles: Nat;
    };

    func benchmark(fn: () -> ()): Benchmark {
        let init_cycles = Cycles.balance();

        let init_heap = Prim.rts_heap_size();
        let init_memory = Prim.rts_memory_size();

        let calls = IC.countInstructions(fn);
        
        {
            calls;
            heap = Prim.rts_heap_size() - init_heap;
            memory = Prim.rts_memory_size() - init_memory;
            cycles = init_cycles - Cycles.balance();
        }
    };

    public query func serialize(n: Nat): async Benchmark {
        benchmark(
            func(){
                let admin_record : Record = {
                    group = "admins";
                    users = ?[{
                        name = "John";
                        age = 32;
                        permission = #admin;
                    }];
                };

                let user_record : Record = {
                    group = "users";
                    users = ?[{
                        name = "Ali";
                        age = 28;
                        permission = #read_all;
                    }, {
                        name = "James";
                        age = 40;
                        permission = #write_all;
                    }];
                };

                let empty_record : Record = {
                    group = "empty";
                    users = ?[];
                };

                let null_record : Record = {
                    group = "null";
                    users = null;
                };

                let base_record : Record = {
                    group = "base";
                    users = ?[{
                        name = "Henry";
                        age = 32;
                        permission = #read(["posts", "comments"]);
                    }, {
                        name = "Steven";
                        age = 32;
                        permission = #write(["posts", "comments"]);
                    }];
                };

                let records : [Record] = [
                    null_record,
                    empty_record,
                    admin_record,
                    user_record,
                    base_record,
                ];

                for (_ in Iter.range(1, n)){
                    let blob = to_candid (records);
                    let #ok(candid) = Candid.decode(blob, [], null);
                    Debug.print(debug_show (candid));
                };
            }
        )
    };

    public query func deserialize(n: Nat) : async Benchmark {
        benchmark(
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
    };

};
