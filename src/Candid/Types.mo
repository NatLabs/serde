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

    public type CandidType = {
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

        #Option : CandidType;
        #Array : CandidType;
        #Record : [(Text, CandidType)];
        #Tuple : [CandidType];
        #Map : [(Text, CandidType)]; // ICRC3 version of #Record
        #Variant : [(Text, CandidType)];
        #Recursive : (Nat);

    };

    // nat values could be either reference pointers to compound types
    // or actual primitive value codes
    public type ShallowCandidTypes = {
        #OptionRef : Nat;
        #ArrayRef : Nat;
        #RecordRef : [(Text, Nat)];
        #VariantRef : [(Text, Nat)];
    };

    public let TypeCode = {
        // primitive types
        Null : Nat8 = 0x7f; // 127
        Bool : Nat8 = 0x7e; // 126
        Nat : Nat8 = 0x7d; // 125
        Int : Nat8 = 0x7c; // 124
        Nat8 : Nat8 = 0x7b; // 123
        Nat16 : Nat8 = 0x7a; // 122
        Nat32 : Nat8 = 0x79; // 121
        Nat64 : Nat8 = 0x78; // 120
        Int8 : Nat8 = 0x77; // 119
        Int16 : Nat8 = 0x76; // 118
        Int32 : Nat8 = 0x75; // 117
        Int64 : Nat8 = 0x74; // 116
        // Float32 : Nat8 = 0x73; // 115
        Float : Nat8 = 0x72; // 114
        Text : Nat8 = 0x71; // 113
        // Reserved : Nat8 = 0x70; // 112
        Empty : Nat8 = 0x6f; // 111

        // compound types

        Option : Nat8 = 0x6e; // 110
        Array : Nat8 = 0x6d; // 109
        Record : Nat8 = 0x6c; // 108
        Variant : Nat8 = 0x6b; // 107
        // Func : Nat8 = 0x6a; // 106
        // Service : Nat8 = 0x69; // 105

        Principal : Nat8 = 0x68; // 104

    };

    /// Encoding and Decoding options
    public type Options = {

        /// #### Encoding Options
        /// Contains an array of tuples of the form (old_name, new_name) to rename the record keys.
        renameKeys : [(Text, Text)];

        // convertAllNumbersToFloats : Bool;

        /// Returns #Map instead of #Record supported by the icrc3 spec
        use_icrc_3_value_type : Bool;

        /// encodes faster if the complete type is known, but not necessary
        /// fails if types are incorrect
        ///
        /// Must call `Candid.formatCandidTypes` before passing in the types
        types : ?[CandidType];

    };

    public type ICRC3Value = {
        #Blob : Blob;
        #Text : Text;
        #Nat : Nat;
        #Int : Int;
        #Array : [ICRC3Value];
        #Map : [(Text, ICRC3Value)];
    };

    public let defaultOptions : Options = {
        renameKeys = [];
        // convertAllNumbersToFloats = false;
        use_icrc_3_value_type = false;

        types = null;

    };

};
