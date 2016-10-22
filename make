#!/usr/bin/env bash


# realpath() {
#     [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
# }



# define all modules (in correct order)
MODULES=(_init async hash overload prototyping tree)
FILES_TO_CAT="debug.coffee "

if [[ "$1" == "--with" ]]; then
    TEMP=""
    for param in ${@:2}; do
        TEMP+="$param "
    done
    MODULES=("$TEMP")
elif [[ "$1" == "--without" ]]; then
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
elif [[ "$1" == "docs" ]]; then
    # options are in .codoopts file
    node_modules/.bin/codo
    exit 0
elif [[ "$1" == "codoopts" ]]; then
    module_files=($(find . -type f -name files.txt))
    files=""
    for module_file in ${module_files[@]}; do
        path=$(dirname $module_file)
        source_files=($(cat $module_file))
        for source_file in ${source_files[@]}; do
            files+="$path/$source_file"
            files+=$'\n'
        done
    done
    echo "--name       \"js_utils\"
--readme     README.md
--title      \"js_utils\"
--private
--quiet
--extension  coffee
--output     ./docs
$files
-
LICENSE" > .codoopts
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
echo 'cat $FILES_TO_CAT | coffee -sc > js_utils.js'
cat $FILES_TO_CAT | coffee -sc > js_utils.js
echo 'uglifyjs js_utils.js -o js_utils.min.js -c drop_console=true -d DEBUG=false -m'
uglifyjs js_utils.js -o js_utils.min.js -c drop_console=true -d DEBUG=false -m
