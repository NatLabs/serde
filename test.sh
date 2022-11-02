#!/bin/sh
LIBS=$(vessel sources)
WASM_FILES=""

for TEST in `ls tests/*Test.mo`
	do
		FILE=`echo ${TEST:6} | awk -F'.' '{print $1}'`
        WASM=tests/$FILE.Test.wasm

        WASM_FILES+=" $WASM"

        printf "\n\n${FILE}.Test.mo ...\n"
        printf '=%.0s' {1..30}
        echo

        $(vessel bin)/moc $LIBS -wasi-system-api $TEST -o $WASM
        # RES=`wasmtime $WASM`

        # CHECK_RES=`echo $RES | grep "Tests failed"`

        wasmtime $WASM
        rm -f $WASM
        # if [$CHECK_RES = ""];
        # then 
        #     printf $RES
        #     rm -f $WASM
        #     exit 1
        # else
        #     printf $RES
        #     rm -f $WASM
        # fi
	done
