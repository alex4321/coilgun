#!/bin/bash
CALC="`winepath -w calc.lua`"
#CALC="calc.lua"
FEMM_PATH="$HOME/.wine/drive_c/femm42/bin/femm.exe"
time wine "$FEMM_PATH" "-lua-script=$CALC" #-windowhide