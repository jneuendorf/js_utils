#!/usr/bin/env bash


# define all modules (in correct order)
MODULES=(_init async hash overload prototyping tree)
FILES_TO_CAT="debug.coffee "

if [[ "$1" == "with" ]]; then
    TEMP=""
    for param in ${@:2}; do
        TEMP+="$param "
    done
    MODULES=("$TEMP")
elif [[ "$1" == "without" ]]; then
    TEMP="${MODULES[@]}"
    for param in ${@:2}; do
        TEMP=${TEMP/$param/""}
    done
    MODULES=("$TEMP")
# TESTS
elif [[ "$1" == "test" ]]; then
    for module in ${MODULES[@]}; do
        MODULE_TEST_FILES=($(cat $module/testfiles.txt))
        for module_test_file in ${MODULE_TEST_FILES[@]}; do
            FILES_TO_CAT+="$module/$module_test_file "
        done
    done
    cat $FILES_TO_CAT | coffee -sc > js_utils.test.js
    exit 0
fi

for module in ${MODULES[@]}; do
    MODULE_FILES=($(cat $module/files.txt))
    for module_file in ${MODULE_FILES[@]}; do
        FILES_TO_CAT+="$module/$module_file "
    done
done

# echo $FILES_TO_CAT

# --compile --stdio
cat $FILES_TO_CAT | coffee -sc > js_utils.js
uglifyjs js_utils.js -o js_utils.min.js -c drop_console=true -d DEBUG=false -m