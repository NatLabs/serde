# serde

A serialisation and deserialisation library for Motoko.

[Motoko Playground Demo](https://m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app/?tag=3196250840)

## Installation
- Install [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install)
- Run `mops install serde`, in your project directory

## Usage
#### Import statement 
```motoko
import { JSON; Candid; UrlEncoded } "mo:serde";
```

### JSON
This is an example of using the serde library using JSON as the data format, since most applications will JSON data for communicating with http clients and services. The API for each module is the same, so the same code can be used for converting between the other modules (Candid and URL-Encoded Pairs).

- Converting a specific data type, for example `User`:

#### JSON to Motoko
- **Specifying the data type**
The most important part of using the serde library is specifying the data type because this tells the global `from_candid` and `to_candid` functions how to properly convert the data.

For this example, we will be converting an array of users from JSON to Motoko and vice versa. Here is an example of the json data we will be converting:
```json
[
    {
        "name": "John",
        "id": 123
    },
    {
        "name": "Jane",
        "id": 456,
        "email": "jane@gmail.com"
    }
]
```
  You can observe that the `email` field is optional, so we will need to specify that in the Motoko type definition.

  ```motoko
      type User = {
          name: Text;
          id: Nat;
          email: ?Text;
      };
  ```

  - **Converting to Motoko**
    - The first step is to generate a candid blob from the json text using `JSON.fromText`. This function tries to determine the datatypes best type by traversing the data tree and choosing the highest level type that can be used to represent the data. It returns a `Result<Blob, Text>` type where #ok(Blob) is returned if it succeeds and #err(Text) is returned if it fails. 
    - The `Blob` type is a candid blob that can be converted to Motoko using the `from_candid` function.
    - Now that we have defined our type, we specify the type when converting with the `from_candid` function. This function tries to convert the candid blob to the type specified by the user. If the conversion fails, it will return a `null` value and if it is succeeds it will return the converted data wrapped in an `Option` type. 

  ```motoko
        let jsonText = "[{\"name\": \"John\", \"id\": 123}, {\"name\": \"Jane\", \"id\": 456, \"email\": \"jane@gmail.com\"}]";

        let #ok(blob) = JSON.fromText(jsonText, null);
        let users : ?[User] = from_candid(blob);

        assert users == ?[
            {
                name = "John";
                id = 123;
                email = null;
            },
            {
                name = "Jane";
                id = 456;
                email = ?"jane@gmail.com";
            },
        ];

  ```

#### Motoko to JSON
- **data type** -> We will be using the same `User` type from the previous example.
- **Adding type record keys**
  - For all the unique record keys in your data type, you will need to add them to a list of record keys. This will allow the json module to properly convert the field names to their correct text format as the `to_candid()` function return their hash value instead of their original name.
  ```motoko
      let UserKeys = ["name", "id", "email"];
  ```
- **Converting to JSON**
  ```motoko

      let users : [User] = [
          {
              name = "John";
              id = 123;
              email = null;
          },
          {
              name = "Jane";
              id = 456;
              email = ?"jane@gmail.com";
          },
      ];

      let blob = to_candid(users);
      let json = JSON.toText(blob, UserKeys, null);

      assert json == "[{\"name\": \"John\",\"id\": 123},{\"name\": \"Jane\",\"id\":456,\"email\":\"jane@gmail.com"}]";
   ```

#### Renaming field keys (Useful for fields with reserved keywords in Motoko )
```motoko
    import Serde "mo:serde";

    // type JsonItemSchemaWithReservedKeys = {
    //     type: Text; // reserved
    //     label: Text;  // reserved
    //     id: Nat;
    // };

    type Item = {
        item_type: Text;
        item_label: Text;
        id: Nat
    };

    let jsonText = "{\"type\": \"bar\", \"label\": \"foo\", \"id\": 112}";
    let options : Serde.Options = { 
        renameKeys = [("type", "item_type"), ("label", "item_label")] 
    };

    let blob = Serde.JSON.fromText(jsonText, ?options);
    let renamedKeys : ?Item = from_candid(blob);

    assert renamedKeys == ?{ item_type = "bar"; item_label = "foo"; id = 112 };
```
For more usage examples see [usage.md](https://github.com/NatLabs/serde/blob/main/usage.md):
- [Candid Text](https://github.com/NatLabs/serde/blob/main/usage.md#candid-text)
- [URL-Encoded Pairs](https://github.com/NatLabs/serde/blob/main/usage.md#url-encoded-pairs)

## Limitations
- Requires that the user provides a list of record keys and variant names when converting from Motoko. This is because the candid format used for serializing Motoko stores record keys as their hash, making it impossible to retrieve the original key names.
- Does not have specific syntax to support the conversion between `Blob`, `Principal`, and Bounded `Nat`/`Int` types.


## Tests
- Install [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install)
- Install [mocv](https://github.com/ZenVoich/mocv)
- Install [wasmtime](https://github.com/bytecodealliance/wasmtime/blob/main/README.md#wasmtime)

- Run `mops test` in the project directory