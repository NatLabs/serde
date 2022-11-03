
test:
	$(shell vessel bin)/moc -r $(shell vessel sources) -wasi-system-api ./tests/*Test.mo

test1:
	bash test.sh

.PHONY: %.tested
%.tested: %Test.mo
	$(shell vessel bin)/moc $(shell vessel sources) -wasi-system-api -o ./tests/$@.Test.wasm ./tests/$@.Test.mo && wasmtime ./tests/$@.Test.mo && rm -f ./tests/$@.Test.mo

docs:
	$(shell vessel bin)/mo-doc