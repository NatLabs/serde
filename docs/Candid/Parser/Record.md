# Candid/Parser/Record

## Function `recordParser`
``` motoko no-repl
func recordParser(candidParser : () -> Parser<Char, Candid>) : Parser<Char, Candid>
```


## Function `fieldParser`
``` motoko no-repl
func fieldParser<Candid>(valueParser : () -> Parser<Char, Candid>) : Parser<Char, (Text, Candid)>
```


## Function `keyParser`
``` motoko no-repl
func keyParser() : Parser<Char, Text>
```

