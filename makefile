.PHONY: test no-warn docs

test:
	bash test.sh

no-warn:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc -r $(shell mops sources) -Werror -wasi-system-api

docs:
	$(shell vessel bin)/mo-doc
	$(shell vessel bin)/mo-doc --format plain
