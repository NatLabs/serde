# Candid/Parser/Common

## Function `ignoreSpace`
``` motoko no-repl
func ignoreSpace<A>(parser : P.Parser<Char, A>) : P.Parser<Char, A>
```


## Function `removeUnderscore`
``` motoko no-repl
func removeUnderscore<A>(parser : P.Parser<Char, A>) : P.Parser<Char, List<A>>
```


## Function `any`
``` motoko no-repl
func any<T>() : Parser<T, T>
```


## Function `hexChar`
``` motoko no-repl
func hexChar() : Parser<Char, Char>
```


## Function `consIf`
``` motoko no-repl
func consIf<T, A>(parserA : Parser<T, A>, parserAs : Parser<T, List<A>>, cond : (A, List<A>) -> Bool) : Parser<T, List<A>>
```


## Function `fromHex`
``` motoko no-repl
func fromHex(char : Char) : Nat8
```


## Function `toText`
``` motoko no-repl
func toText(chars : List<Char>) : Text
```


## Function `listToNat`
``` motoko no-repl
func listToNat(digits : List<Char>) : Nat
```

