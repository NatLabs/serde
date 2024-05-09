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
