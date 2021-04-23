# Setup
Check values in `.env`, edit if necessary.

Run setup script to prepare sql files in `init` folder:
```shell
./scripts/setup.sh
```

Set up Postgres. Sql files in `init` folder will be executed. On my Macbook Pro, this takes about 5 minutes. For status, see log file in `pg_logs` folder, or `docker-compose logs` (latter is very noisy due to inserts).
```shell
docker-compose up -d
```

Build the Java app:
```shell
./gradlew build
```

After init we have WAL files:
```
pg_data/pg_wal/
├── 000000010000000000000001
├── 000000010000000000000002
├── 000000010000000000000003
├── 000000010000000000000004
├── 000000010000000000000005
├── 000000010000000000000006
├── 000000010000000000000007
├── 000000010000000000000008
├── 000000010000000000000009
├── 00000001000000000000000A
├── 00000001000000000000000B
├── 00000001000000000000000C
├── 00000001000000000000000D
└── archive_status
```

We also have 4 replication slots at different points in WAL. Get the exact values from the database:
```shell
./scripts/run_sql.sh 'SELECT slot_name, restart_lsn, confirmed_flush_lsn FROM pg_replication_slots order by 1'

  slot_name  | restart_lsn | confirmed_flush_lsn 
-------------+-------------+---------------------
 test_slot_1 | 0/15E11A0   | 0/15E11D8
 test_slot_2 | 0/39A05E0   | 0/39A0618
 test_slot_3 | 0/5FE2B80   | 0/5FE2BB8
 test_slot_4 | 0/84C3BC8   | 0/84C3C00
(4 rows)
```

The WAL contains 4 major parts:
1. 100k inserts as single-statement transactions
2. Single transaction updating 100k rows
3. 100k inserts as single-statement transactions
4. Single transaction updating 200k rows

The positions where each part starts map to the `restart_lsn` of the 4 replication slots.

### Test case 1
test_slot_1 to end of 100k inserts
```shell
./scripts/run_test.sh test_slot_1 0/3900000
```
### Test case 2
test_slot_1 to beginning of update
```shell
./scripts/run_test.sh test_slot_1 0/39A05E0
```
### Test case 3
test_slot_1 to end of second 100k inserts
```shell
./scripts/run_test.sh test_slot_1 0/8000000
```
### Test case 4
test_slot_1 to beginning of second update
```shell
./scripts/run_test.sh test_slot_1 0/84C3BC8
```

# Other
WAL files can be analyzed with `pg_waldump` inside the docker container.

See `scripts/waldump.sh` for convenience:
```shell
./scripts/waldump.sh 000000010000000000000001
```
```shell
./scripts/waldump.sh 000000010000000000000003 000000010000000000000004
```

Re-initializing the database after wiping `pg_data` sometimes causes docker-compose to hang.
Restarting Docker helps:
```
killall Docker && open /Applications/Docker.app
```

See changes
```shell
./scripts/run_sql.sh "select pg_logical_slot_peek_changes('test_slot_1', <to_lsn|null>, <n of changes|null>)"
```

Print some interesting LSNs, takes a while (3-5 mins for me).
```shell
./scripts/run_sql.sh "select pg_logical_slot_peek_changes('test_slot_1', null, null)" |grep -E ":1 data|00000 data|00001 data" |awk '{print $1 " " $2 " " $3 " " $4}'
```

Lines per WAL file?
```shell
for f in `find ./pg_data/pg_wal/0*`; do wc -l $f; done
  118958 ./pg_data/pg_wal/000000010000000000000001
   54120 ./pg_data/pg_wal/000000010000000000000002
   69950 ./pg_data/pg_wal/000000010000000000000003
   90892 ./pg_data/pg_wal/000000010000000000000004
  105003 ./pg_data/pg_wal/000000010000000000000005
   51249 ./pg_data/pg_wal/000000010000000000000006
   54376 ./pg_data/pg_wal/000000010000000000000007
   78909 ./pg_data/pg_wal/000000010000000000000008
   98281 ./pg_data/pg_wal/000000010000000000000009
  176839 ./pg_data/pg_wal/00000001000000000000000A
   90876 ./pg_data/pg_wal/00000001000000000000000B
   91198 ./pg_data/pg_wal/00000001000000000000000C
   19053 ./pg_data/pg_wal/00000001000000000000000D
```

WIP get cutoff LSNs
```
./scripts/waldump.sh 000000010000000000000001 00000001000000000000000D \
|./scripts/analyze_wal.awk \
|sed 's/^ +//g' \
|sed 's/,$//g'
```