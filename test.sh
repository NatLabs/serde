#!/bin/sh
LIBS=$(mops sources)
WASM_FILES=""

LS_DIR=`ls tests/*.Test.mo`
if [ -z $1 ]
then
    echo "No argument supplied"
else
    echo $1
    LS_DIR=`ls tests/*.Test.mo | grep $1`
fi


for TEST in $LS_DIR
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
