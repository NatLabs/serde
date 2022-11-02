module {
    public type KeyValuePair = (Text, Candid);

    public type Candid = {
        #Int : Int;
        #Int8 : Int8;
        #Int16 : Int16;
        #Int32 : Int32;
        #Int64 : Int64;

        #Nat : Nat;
        #Nat8 : Nat8;
        #Nat16 : Nat16;
        #Nat32 : Nat32;
        #Nat64 : Nat64;

        #Bool : Bool;

        #Float32 : Float;
        #Float64 : Float;

        #Text : Text;

        #Null;
        #Empty;
        #Principal : Principal;

        #Option : Candid;
        #Vector : [Candid];
        #Record : [KeyValuePair];
        #Variant : [KeyValuePair];

        // #Reserved;
        // #Func : FuncType;
        // #Service : ServiceType;
    };

};
