
test:
	$(shell vessel bin)/moc -r $(shell vessel sources) -wasi-system-api ./tests/*Test.mo

test1:
	$(shell vessel bin)/moc $(shell vessel sources) -wasi-system-api -o Test.wasm tests/*Test.mo && wasmtime test.wasm && rm -f Test.wasm

docs:
	$(shell vessel bin)/mo-doc