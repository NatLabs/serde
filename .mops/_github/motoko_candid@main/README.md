## Funding

This library was originally incentivized by [ICDevs](https://ICDevs.org). You
can view more about the bounty on the
[forum](https://forum.dfinity.org/t/icdevs-org-bounty-18-cbor-and-candid-motoko-parser-3-000/11398)
or [website](https://icdevs.org/bounties/2022/02/22/CBOR-and-Candid-Motoko-Parser.html). The
bounty was funded by The ICDevs.org commuity and the award paid to
@Gekctek. If you use this library and gain value from it, please consider
a [donation](https://icdevs.org/donations.html) to ICDevs.

# Overview

This is a library that enables encoding/decoding of bytes to candid values

# Package

### Vessel

Currently there is no official package but there is a manual process:

1. Add the following to the `additions` list in the `package-set.dhall`

```
{
    name = "candid"
    , version = "{{Version}}"
    , repo = "https://github.com/gekctek/motoko_candid"
    , dependencies = [] : List Text
}
```

Where `{{Version}}` should be replaced with the latest release from https://github.com/Gekctek/motoko_numbers/releases/

2. Add `candid` as a value in the dependencies list
3. Run `./build.sh` which runs the vessel command to install the package

# Usage

Example of `call_raw` usage:

```
func call_raw(p : Principal, m : Text, a : Blob) : async Blob {
    // Parse parameters
    let args: [Arg.Arg] = switch(Decoder.decode(a)) {
        case (null) Debug.trap("Invalid candid");
        case (?c) c;
    };

    // Validate request...

    // Process request...

    // Return result
    let returnArgs: [Arg.Arg] = [
        {
            _type=#Bool;
            value=#Bool(true)
        }
    ];
    Encoder.encode(returnArgs);
};
```

# API

## Decoder

`decode(candidBytes: Blob) : ?[Arg.Arg]`

Decodes a series of bytes to CandiArgs. If invalid candid bytes, will return null

## Encoder

`encode(args: [Arg.Arg]) : Blob`

Encodes an array of candid arguments to bytes

`encodeToBuffer(buffer : Buffer.Buffer<Nat8>, args : [Arg.Arg]) : ()`

Encodes an array of candid arguments to a byte buffer

## Tag

`hash(t : Tag) : Nat32`

Hashes a tag name to a Nat32. If already hashed, will use hash value

`hashName(name : Text) : Nat32`

Hashes a tag name to a Nat32

`equal(t1: Tag, t2: Tag) : Bool`

Checks for equality between two tags

`compare(t1: Tag, t2: Tag) : Order.Order`

Compares order between two tags

## Type

`equal(v1: Type, v2: Type): Bool`

Checks for equality between two types

`hash(t : Type) : Hash.Hash`

Hashes a type to a Nat32

## Value

`equal(v1: Value, v2: Value): Bool`

Checks for equality between two values

# Library Devlopment:

## First time setup

To build the library, the `Vessel` library must be installed. It is used to pull down packages and locate the compiler for building.

https://github.com/dfinity/vessel

## Building

To build, run the `./build.sh` file. It will output wasm files to the `./build` directory

## Testing

To run tests, use the `./test.sh` file.
The entry point for all tests is `test/Tests.mo` file
It will compile the tests to a wasm file and then that file will be executed.
Currently there are no testing frameworks and testing will stop at the first broken test. It will then output the error to the console

## TODO

- Opaque reference byte encoding/decoding
- Error messaging vs null return type for decoding
- Better/Documented error messages
- More test cases
- Use testing framework
