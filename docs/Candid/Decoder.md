# Candid/Decoder

## Type `Options`
``` motoko no-repl
type Options = { renameKeys : [(Text, Text)] }
```


## Function `decode`
``` motoko no-repl
func decode(blob : Blob, record_keys : [Text], options : ?Options) : [Candid]
```

Decodes a blob encoded in the candid format into a list of the [Candid](./Types.mo#Candid) type in motoko

### Inputs
- **blob** -  A blob encoded in the candid format
**record_keys** - The record keys to use when decoding a record.
**options** - An optional arguement to specify options for decoding.

## Function `fromArgs`
``` motoko no-repl
func fromArgs(args : [Arg], recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : [Candid]
```

