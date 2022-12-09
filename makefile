test:
	bash test.sh

_test:
	$(shell vessel bin)/moc -r $(shell vessel sources) -wasi-system-api ./tests/*Test.mo

.PHONY: %.tested docs

%.tested: %Test.mo
	$(shell vessel bin)/moc $(shell vessel sources) -wasi-system-api -o ./tests/$@.Test.wasm ./tests/$@.Test.mo && wasmtime ./tests/$@.Test.wasm && rm -f ./tests/$@.Test.mo

tests/Candid.Test.wasm: tests/Candid.Test.mo
	$(shell vessel bin)/moc $(shell vessel sources) -wasi-system-api -o ./tests/Candid.Test.wasm ./tests/Candid.Test.mo

tests/Candid.Test: tests/Candid.Test.wasm
	wasmtime ./tests/Candid.Test.wasm

tests/UrlEncoded.Test.wasm: tests/UrlEncoded.Test.mo src/UrlEncoded
	$(shell vessel bin)/moc $(shell vessel sources) -wasi-system-api -o ./tests/UrlEncoded.Test.wasm ./tests/UrlEncoded.Test.mo

UrlEncoded: tests/UrlEncoded.Test.wasm
	wasmtime ./tests/UrlEncoded.Test.wasm

docs:
	$(shell vessel bin)/mo-doc