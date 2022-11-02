import Arg "mo:motoko_candid/Arg";
import Value "mo:motoko_candid/Value";
import Type "mo:motoko_candid/Type";

module {
    public type Arg = Arg.Arg;
    public type Type = Type.Type;
    public type Value = Value.Value;
    public type RecordFieldType = Type.RecordFieldType;
    public type RecordFieldValue = Value.RecordFieldValue;

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
