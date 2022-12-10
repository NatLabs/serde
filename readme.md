# serde

A serialisation and deserialisation library for Motoko.

## Installation
- Install [mops]()
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

### URL-Encoded Pairs
support for the `application/x-www-form-urlencoded` content type.

This is a loose implementation, as it also supports arrays and nested objects in the form of `items[0]=value&items[1]=value` and `items[subKey]=value`.


```motoko
    import serde_urlencoded "mo:serde/URLEncoded";
    
    type User = {
        name: Text;
        id: Text; // only supports Text for now
    };
    
    let payload = "users[0][id]=123&users[0][name]=John&users[1][id]=456&users[1][name]=Jane";

    let blob = serde_urlencoded.fromText(payload);
    let res : ?{ users: [User]} = from_candid(blob);

    assert res == ?{ users = [
        {
            name = "John";
            id = "123";
        },
        {
            name = "Jane";
            id = "456";
        },
    ] };

```
