#!/bin/bash
docker exec -it pg_troublesh_postgres_1 pg_waldump -p /var/lib/postgresql/data/ "$@"