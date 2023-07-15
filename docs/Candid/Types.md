# Candid/Types

## Type `KeyValuePair`
``` motoko no-repl
type KeyValuePair = (Text, Candid)
```


## Type `Candid`
``` motoko no-repl
type Candid = {#Int : Int; #Int8 : Int8; #Int16 : Int16; #Int32 : Int32; #Int64 : Int64; #Nat : Nat; #Nat8 : Nat8; #Nat16 : Nat16; #Nat32 : Nat32; #Nat64 : Nat64; #Bool : Bool; #Float : Float; #Text : Text; #Blob : Blob; #Null; #Empty; #Principal : Principal; #Option : Candid; #Array : [Candid]; #Record : [KeyValuePair]; #Variant : KeyValuePair}
```

A standard representation of the Candid type
