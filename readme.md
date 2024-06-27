# `serde` for Motoko

An efficient serialization and deserialization library for Motoko.

The library contains four modules:
- **Candid**
    - `fromText()` - Converts [Candid text](https://internetcomputer.org/docs/current/tutorials/developer-journey/level-2/2.4-intro-candid/#candid-textual-values) to its serialized form.
    - `toText()` - Converts serialized candid to its [textual representation](https://internetcomputer.org/docs/current/tutorials/developer-journey/level-2/2.4-intro-candid/#candid-textual-values).
    - `encode()` - Converts the [Candid variant](./src/Candid/Types.mo#L6) to a blob.
    - `decode()` - Converts a blob to the [Candid variant](./src/Candid/Types.mo#L6).
    > encoding and decoding functions also support conversion between the [`ICRC3` value type](https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3#value) and candid. Checkout the example in the [usage guide](./usage.md#icrc3-value)
- **CBOR**
    - `encode()` - Converts serialized candid to CBOR.
    - `decode()` - Converts CBOR to a serialized candid.

- **JSON**
    - `fromText()` - Converts JSON text to serialized candid.
    - `toText()` - Converts serialized candid to JSON text.

- **URL-Encoded Pairs**
    - `fromText()` - Converts URL-encoded text to serialized candid.
    - `toText()` - Converts serialized candid to URL-encoded text.
  

## Getting Started

### Installation 
[![mops](https://oknww-riaaa-aaaam-qaf6a-cai.raw.ic0.app/badge/mops/serde)](https://mops.one/serde)

1. Install [`mops`](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install).
2. Inside your project directory, run: 
```bash
mops install serde
```

### Usage

To start, import the necessary modules:
```motoko
import { JSON; Candid; CBOR; UrlEncoded } from "mo:serde";
```

#### JSON
> The following code can be used for converting data between the other modules (Candid and URL-Encoded Pairs).

**Example: JSON to Motoko**

1. **Defining Data Type**: This critical step informs the conversion functions (`from_candid` and `to_candid`) about how to handle the data.

   Consider the following JSON data:
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

   The optional `email` field translates to:
   
   ```motoko
   type User = {
       name: Text;
       id: Nat;
       email: ?Text;
   };
   ```

2. **Conversion**:
   a. Parse JSON text into a candid blob using `JSON.fromText`.
   b. Convert the blob to a Motoko data type with `from_candid`.

   ```motoko
   let jsonText = "[{\"name\": \"John\", \"id\": 123}, {\"name\": \"Jane\", \"id\": 456, \"email\": \"jane@gmail.com\"}]";

   let #ok(blob) = JSON.fromText(jsonText, null); // you probably want to handle the error case here :)
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

**Example: Motoko to JSON**

1. **Record Keys**: Collect all unique record keys from your data type into an array. This helps the module convert the record keys correctly instead of returning its hash.
   
   ```motoko
   let UserKeys = ["name", "id", "email"];
   ```

2. **Conversion**:
   
   ```motoko
   let users: [User] = [
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
   let json_result = JSON.toText(blob, UserKeys, null);

   assert json_result == #ok(
        "[{\"name\": \"John\",\"id\": 123},{\"name\": \"Jane\",\"id\":456,\"email\":\"jane@gmail.com\"}]"
    );
   ```

**Example: Renaming Fields**

- Useful way to rename fields with reserved keywords in Motoko.

```motoko
import Serde from "mo:serde";

    // type JsonSchemaWithReservedKeys = {
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
let options: Serde.Options = { 
    renameKeys = [("type", "item_type"), ("label", "item_label")] 
};

let #ok(blob) = Serde.JSON.fromText(jsonText, ?options);
let renamedKeys: ?Item = from_candid(blob);

assert renamedKeys == ?{ item_type = "bar"; item_label = "foo"; id = 112 };
```

Checkout the [usage guide](https://github.com/NatLabs/serde/blob/main/usage.md) for additional examples:
- [Candid](https://github.com/NatLabs/serde/blob/main/usage.md#candid-text)
- [URL-Encoded Pairs](https://github.com/NatLabs/serde/blob/main/usage.md#url-encoded-pairs)

## Limitations

- Users must provide a list of record keys and variant names during conversions from Motoko to other data formats due to constraints in the candid format.
- Lack of specific syntax for conversion between `Blob`, `Principal`, and bounded `Nat`/`Int` types.
- Cannot deserialize Tuples as they are not candid types. They are just shorthands for records with unnamed fields. See https://forum.dfinity.org/t/candid-and-tuples/17800/7
- Floats are only recognised if they have a decimal point, e.g., `1.0` is a Float, but `1` is an `Int` / `Nat`.
- Only supports candid data types (i.e primitive and constructed types). Service and function reference types are not supported.

## Running Tests

1. Install dependencies:
   - [mops](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/#/docs/install)
   - [mocv](https://github.com/ZenVoich/mocv)
   - [wasmtime](https://github.com/bytecodealliance/wasmtime/blob/main/README.md#wasmtime)

2. Inside the project directory, run:
```bash
mops test
```

---

Happy coding with `serde`! 🚀