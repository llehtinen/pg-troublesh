#!/bin/bash
CONTAINER=$(docker-compose ps|grep -vE " Name |----" |awk '{print $1}')
docker exec -it $CONTAINER pg_waldump -p /var/lib/postgresql/data/ "$@"
