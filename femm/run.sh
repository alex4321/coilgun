#!/bin/bash
CONFIG="$1"
RESULT_DIR="`realpath $2`"
TMP_DIR="`mktemp -d`"
CALC="`winepath -w calc.lua`"
FEMM_PATH="$HOME/.wine/drive_c/femm42/bin/femm.exe"

DIR="`pwd`"

cp "$CONFIG" "$TMP_DIR/config.lua"
cd "$TMP_DIR"
time nice -n 1 wine "$FEMM_PATH" "-lua-script=$CALC" #-windowhide
cp *.txt "$RESULT_DIR"

cd "$DIR"
rm -r "$TMP_DIR"