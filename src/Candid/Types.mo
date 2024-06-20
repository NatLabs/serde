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
        #Tuple : [Candid]; // shorthand for record with indexed keys -> #Record([(0, Candid), (1, Candid), ...])
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
        #Recursive : (Nat, CandidTypes);

    };

    public let TypeCode = {
        // primitive types
        Null : Nat8 = 0x7f;
        Bool : Nat8 = 0x7e;
        Nat : Nat8 = 0x7d;
        Int : Nat8 = 0x7c;
        Nat8 : Nat8 = 0x7b;
        Nat16 : Nat8 = 0x7a;
        Nat32 : Nat8 = 0x79;
        Nat64 : Nat8 = 0x78;
        Int8 : Nat8 = 0x77;
        Int16 : Nat8 = 0x76;
        Int32 : Nat8 = 0x75;
        Int64 : Nat8 = 0x74;
        // Float32 : Nat8 = 0x73;
        Float : Nat8 = 0x72;
        Text : Nat8 = 0x71;
        // Reserved : Nat8 = 0x70;
        Empty : Nat8 = 0x6f;
        Principal : Nat8 = 0x68;

        // compound types

        Option : Nat8 = 0x6e;
        Array : Nat8 = 0x6d;
        Record : Nat8 = 0x6c;
        Variant : Nat8 = 0x6b;
        // Func : Nat8 = 0x6a;
        // Service : Nat8 = 0x69;

    };

    /// Encoding and Decoding options
    public type Options = {
        /// Contains an array of tuples of the form (old_name, new_name) to rename the record keys.
        renameKeys : [(Text, Text)];

        // convertAllNumbersToFloats : Bool;

        use_icrc_3_value_type : Bool;
        
        /// encodes faster if the complete type is known, but not necessary
        /// fails if types are incorrect
        types : ?[CandidTypes]; 

    };

    public let defaultOptions = {
        renameKeys = [];
        // convertAllNumbersToFloats = false;
        use_icrc_3_value_type = false;

        types = null;
    };

};
