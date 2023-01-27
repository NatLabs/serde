# serde

A serialisation and deserialisation library for Motoko.

[Motoko Playground Demo](https://m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app/?tag=3196250840)

## Installation
- Install [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install)
- Run `mops install serde`, in your project directory

## Usage

### JSON

```motoko
    import serdeJson "mo:serde/JSON";
    
    type User = {
        name: Text;
        id: Nat;
    };

    let blob = serdeJson.fromText("{\"name\": \"bar\", \"id\": 112}");
    let user : ?User = from_candid(blob);

    assert user == ?{ name = "bar"; id = 112 };

```

### Candid Text
```motoko
    import serdeCandid "mo:serde/Candid";

    type User = {
        name: Text;
        id: Nat;
    };

    let blob = serdeCandid.fromText("(record({ name = \"bar\"; id = 112 })");
    let user : ?User = from_candid(blob);

    assert user == ?{ name = "bar"; id = 112 };

```

### URL-Encoded Pairs
Serialization and deserialization for `application/x-www-form-urlencoded`.

This implementation supports URL query strings and URL-encoded pairs, including arrays and nested objects, using the format `items[0]=value&items[1]=value` and `items[subKey]=value`."

```motoko
    import serde_urlencoded "mo:serde/URLEncoded";
    
    type User = {
        name: Text;
        id: Nat; 
    };
    
    let payload = "users[0][id]=123&users[0][name]=John&users[1][id]=456&users[1][name]=Jane";

    let blob = serde_urlencoded.fromText(payload);
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
## Tests
- Install [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install)
- Install [vessel](https://github.com/dfinity/vessel)
- Install [wasmtime](https://github.com/bytecodealliance/wasmtime/blob/main/README.md#wasmtime)

- Run `make compile-tests`