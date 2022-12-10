#!/usr/bin/env bash

dir=build
if [[ ! -e $dir ]]; then
    mkdir -p $dir
fi
for filename in "Arg" "Decoder" "Encoder" "FuncMode" "Tag" "TransparencyState" "Type" "TypeCode" "Value"
do
    echo "Building $filename..."
    $(vessel bin)/moc $(vessel sources) -wasi-system-api "./src/$filename.mo" -o $dir/$filename.wasm
    echo "Building $filename complete"
done