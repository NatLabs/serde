
## Usage Examples

### CBOR 

```mokoto
    import { CBOR } "mo:serde";

    type User = {
        name: Text;
        id: Nat;
    };

    let user : User = { name = "bar"; id = 112 };

    let candid = to_candid (user);
    let cbor_res = CBOR.encode(candid, ["name", "id"], null);
    let #ok(cbor) = cbor_res;
```

### Candid Text
```motoko
    import { Candid } "mo:serde";

    type User = {
        name: Text;
        id: Nat;
    };

    let #ok(blob) = Candid.fromText("(record({ name = \"bar\"; id = 112 }))", null);
    let user : ?User = from_candid(blob);

    assert user == ?{ name = "bar"; id = 112 };

```

### URL-Encoded Pairs
Serialization and deserialization for `application/x-www-form-urlencoded`.

This implementation supports URL query strings and URL-encoded pairs, including arrays and nested objects, using the format `items[0]=value&items[1]=value` and `items[subKey]=value`."

```motoko
    import { URLEncoded } "mo:serde";
    
    type User = {
        name: Text;
        id: Nat; 
    };
    
    let payload = "users[0][id]=123&users[0][name]=John&users[1][id]=456&users[1][name]=Jane";

    let #ok(blob) = URLEncoded.fromText(payload, null);
    let res : ?{ users: [User]} = from_candid(blob);

    assert res == ?{ users = [
        {
            name = "John";
            id = 123;
        },
        {
            name = "Jane";
            id = 456;
        },
    ] };

```
