import Variant "Text/Parser/Variant";
import Record "Text/Parser/Record";
import Principal "Text/Parser/Principal";
import Float "Text/Parser/Float";
import Nat8 "mo:base/Nat8";
module {

    public type KeyValuePair = (Text, Candid);

    /// A standard representation of the Candid type
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
        #Float : Float;
        #Text : Text;
        #Blob : Blob;

        #Null;
        #Empty;
        #Principal : Principal;

        #Option : Candid;
        #Array : [Candid];
        #Record : [KeyValuePair];
        #Map : [KeyValuePair];
        #Variant : KeyValuePair;
    };

    public type CandidTypes = {
        #Int;
        #Int8;
        #Int16;
        #Int32;
        #Int64;

        #Nat;
        #Nat8;
        #Nat16;
        #Nat32;
        #Nat64;
        #Bool;
        #Float;
        #Text;
        #Blob;
        #Null;
        #Empty;
        #Principal;

        #Option : CandidTypes;
        #Array : CandidTypes;
        #Record : [(Text, CandidTypes)];
        #Variant : [(Text, CandidTypes)];
        #Recursive: (Nat, CandidTypes);

    };


    public let TypeCode = {
        // primitive types
        Null = 0x7f;
        Bool = 0x7e;
        Nat = 0x7d;
        Int = 0x7c;
        Nat8 = 0x7b;
        Nat16 = 0x7a;
        Nat32 = 0x79;
        Nat64 = 0x78;
        Int8 = 0x77;
        Int16 = 0x76;
        Int32 = 0x75;
        Int64 = 0x74;
        // Float32 = 0x73;
        Float = 0x72;
        Text = 0x71;
        // Reserved = 0x70;
        Empty = 0x6f;
        Principal = 0x68;
        
        // compound types

        Option = 0x6e;
        Array = 0x6d;
        Record = 0x6c;
        Variant = 0x6b;
        // Func = 0x6a;
        // Service = 0x69;

    }

    /// Encoding and Decoding options
    public type Options = {
        /// Contains an array of tuples of the form (old_name, new_name) to rename the record keys.
        renameKeys : [(Text, Text)];

        // convertAllNumbersToFloats : Bool;

        use_icrc_3_value_type : Bool;
    }; 

    public let defaultOptions = {
        renameKeys = [];
        // convertAllNumbersToFloats = false;
        use_icrc_3_value_type = false;
    };

};
