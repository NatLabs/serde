# JSON/FromText

## Function `fromText`
``` motoko no-repl
func fromText(rawText : Text) : Blob
```

Converts JSON text to a serialized Candid blob that can be decoded to motoko values using `from_candid()`

## Function `toCandid`
``` motoko no-repl
func toCandid(rawText : Text) : Candid
```

Convert JSON text to a Candid value
