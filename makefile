
test:
	$(shell vessel bin)/moc -r $(shell vessel sources) -wasi-system-api ./tests/*Test.mo

test1:
	bash test.sh

docs:
	$(shell vessel bin)/mo-doc