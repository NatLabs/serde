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

#### JSON

- Converting a specific data type, for example `User`:
  ```motoko
      type User = {
          name: Text;
          id: Nat;
          email: ?Text;
      };
  ```

  - JSON to Motoko
  ```motoko
      let blob = JSON.fromText("{\"name\": \"bar\", \"id\": 112}", null);
      let user : ?User = from_candid(blob);

      assert user == ?{ name = "bar"; id = 112; email = null };
  ```

  - Motoko to JSON
  ```motoko
      let UserKeys = ["name", "id", "email"];

      let user : User = { name = "bar"; id = 112; email = null };
      let blob = to_candid(user);
      let json = JSON.toText(blob, UserKeys, null);

      assert json == "{\"name\": \"bar\", \"id\": 112, \"email\": null}";
   ```

- Renaming field keys (Useful for fields with reserved keywords in Motoko )
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