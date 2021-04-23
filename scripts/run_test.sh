#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LIB_DIR="$( cd "$DIR/../app/build/libs" &> /dev/null && pwd)"

java -jar $LIB_DIR/app-all.jar $@