.PHONY: compile-tests no-warn docs

compile-tests:
	bash compile-tests.sh $(file)

no-warn:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell mocv bin)/moc -r $(shell mops sources) -Werror -wasi-system-api

docs:
	$(shell mocv bin)/mo-doc
	$(shell mocv bin)/mo-doc --format plain
