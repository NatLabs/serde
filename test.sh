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
        wasmtime $WASM 
        rm -f $WASM
        
	done
