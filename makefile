.PHONY: test no-warn docs

test:
	bash test.sh

no-warn:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc -r $(shell mops sources) -Werror -wasi-system-api

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
	$(shell vessel bin)/mo-doc --format plain
