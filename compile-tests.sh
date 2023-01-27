#!/bin/sh
LIBS=$(mops sources)

TESTS_FILES=`find tests -type f -name '*.Test.mo'`

if [ -z $1 ]
then
    echo "Compiling all test files (*.Test.mo)"
else
    echo $1
    TESTS_FILES=`find tests -type f -name '*.Test.mo' | grep $1`
fi

mkdir -p tests/.wasm

for TEST in $TESTS_FILES
	do
		FILE_NAME=`echo ${TEST:6} | awk -F'.' '{print $1}'`
        printf "\n\n${FILE_NAME}.Test.mo ...\n"
        printf '=%.0s' {1..30}
        echo

        WASM=tests/.wasm/$FILE_NAME.Test.wasm
        SRC=src/$FILE_NAME
        SRC_FILE=$SRC.mo

        IS_COMPILED=0
        
        if [ $TEST -nt $WASM ];
        then 
            echo "Compiling $TEST"
            rm -f $WASM
            $(vessel bin)/moc $LIBS -wasi-system-api $TEST -o $WASM
            IS_COMPILED=1
        fi

        if [ $IS_COMPILED -eq 0 ] && [ -f $SRC_FILE ] && [$SRC_FILE -nt $WASM ];
        then 
            echo "Compiling because $SRC_FILE changed" 
            rm -f $WASM
            $(vessel bin)/moc $LIBS -wasi-system-api $TEST -o $WASM
            IS_COMPILED=1
        fi

        if [ $IS_COMPILED -eq 0 ] && [ -d SRC ]
        then 
            NESTED_FILES=`find $SRC -type f -name '*.mo'`

            for NESTED_FILE in $NESTED_FILES
                do
                    if [ $NESTED_FILE -nt $WASM ]
                    then 
                        echo "Compiling because $NESTED_FILE changed"
                        $(vessel bin)/moc $LIBS -wasi-system-api $TEST -o $WASM
                        IS_COMPILED=1
                        break
                    fi
                done
        fi

        wasmtime $WASM || exit 1

	done
