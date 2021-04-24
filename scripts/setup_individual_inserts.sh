#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INIT_DIR="$( cd "$DIR/../init" &> /dev/null && pwd)"

echo "Generating sql file with 100k inserts"
$DIR/inserts_gen.sh 1 100000 > $DIR/100k.sql

echo "Replacing insert sql scripts in $INIT_DIR with 100k ones"
cp $DIR/100k.sql $INIT_DIR/03_insert_rows.sql
cp $DIR/100k.sql $INIT_DIR/07_insert_rows.sql

rm $DIR/100k.sql
