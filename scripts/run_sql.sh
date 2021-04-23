#!/bin/bash
PGPASSWORD=test_user psql -h localhost -U test_user -c "$@"