#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$DIR/../.env"
PGPASSWORD=$DB_PASS psql -h localhost -p $DB_PORT  -U $DB_USER -c "$@"
