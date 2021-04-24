# Intro
This repository was created to help troubleshoot why it sometimes takes a long time for a Postgres 
logical replication slot to return the first message.

# Setup
> :information_source: These instructions have been written for and tested with a Mac.

Check values in `.env`, edit if necessary.

Run the setup script to prepare sql files in `init` folder:
```shell
./scripts/setup_individual_inserts.sh
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

## Running tests
Test parameters are the slot name and start position:
```shell
./scripts/run_test.sh test_slot_1 0/601D860
```
Console output shows how long it takes until first message is received, what the first returned
message is, and which WAL files were detected to be open during the wait (based on file descriptors).
```shell
01:50:57.117   PostgreSQL 12.3 (Debian 12.3-1.pgdg100+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 64-bit
01:50:57.125   Current LSN: 0/D4A3218, test_slot_1 flushed currently to: 0/165B348
01:50:57.639   NO WAL OPEN
01:50:58.148   Replication slot test_slot_1 opened with starting LSN: 0/601D860
01:50:58.152   Polling for first message
01:50:58.186   000000010000000000000001 is open
01:50:58.286   000000010000000000000002 is open
01:50:58.475   000000010000000000000003 is open
01:51:03.247   000000010000000000000004 is open
01:51:17.178   Polling for first message
01:51:22.773   000000010000000000000005 is open
01:51:35.839   000000010000000000000006 is open
01:51:36.278   Received first message 0/0 after PT38.13S
01:51:36.278   LSN{0/0} BEGIN 100489
01:51:36.289   LSN{0/39DB4A8} table public.test_data: UPDATE: id[integer]:1 data[character varying]:'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque mi libero, maximus eget ultricies et, pellentesque nec enim. Donec vestibulum ligula vel libero aliquet, at commodo arcu placerat. Sed sed aliquam augue. Vestibulum mattis quam eget gravida.'
01:51:36.301   LSN{0/39DB638} table public.test_data: UPDATE: id[integer]:2 data[character varying]:'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque mi libero, maximus eget ultricies et, pellentesque nec enim. Donec vestibulum ligula vel libero aliquet, at commodo arcu placerat. Sed sed aliquam augue. Vestibulum mattis quam eget gravida.'
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
