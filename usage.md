## Usage Examples

### CBOR

```motoko

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

#### Candid Variant

```motoko

    import { Candid } "mo:serde";

    type User = {
        name: Text;
        id: Nat;
    };

    let candid_variant = #Record([
        ("name", #Text("bar")),
        ("id", #Nat(112))
    ]);

    let #ok(blob) = Candid.encode(candid_variant, null);
    let user : ?User = from_candid(blob);

    assert user == ?{ name = "bar"; id = 112 };

```

#### ICRC3 Value

- The [`ICRC3` value type](https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3#value) is a representation of candid types in motoko used for sending information without breaking compatibility between canisters that might change their api/data types over time.

- **Converting from ICRC3 to motoko**

```motoko
    import Serde "mo:serde";

    let { Candid } = Serde;

    type User = { name : Text; id : Nat };

    let icrc3 : Serde.ICRC3Value = #Map([
        ("id", #Nat(112)),
        ("name", #Text("bar")),
    ]);

    let candid_values = Candid.fromICRC3Value([icrc3]);

    let #ok(blob) = Candid.encode(candid_values, null);
    let user : ?User = from_candid (blob);

    assert user == ?{ name = "bar"; id = 112 };

```

- **Converting from motoko to ICRC3**

```motoko
    import Serde "mo:serde";

    let { Candid } = Serde;

    type User = { id : Nat; name : Text };

    let user : User = { name = "bar"; id = 112 };

    let blob = to_candid (user);
    let #ok(candid_values) = Candid.decode(blob, ["name", "id"], null);
    let icrc3_values = Candid.toICRC3Value(candid_values);

    assert icrc3_values[0] == #Map([
        ("id", #Nat(112)),
        ("name", #Text("bar")),
    ]);

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
