#!/usr/bin/awk -f
#rmgr: Transaction len (rec/tot):     46/    46, tx:      72724, lsn: 0/030000E0, prev 0/02FFFF78, desc: COMMIT 2021-04-23 12:09:13.626109 UTC
#rmgr: Heap        len (rec/tot):    318/   318, tx:      72725, lsn: 0/03000110, prev 0/030000E0, desc: INSERT off 12 flags 0x08, blkref #0: rel 1663/16384/16387 blk 2675

BEGIN {
  start=0
  insert=1
  update=0
  last_update=0
  last_insert=0
}

/ lsn: 0\/015/{
  start=1
}

/desc: INSERT /{
  if (start) {
    if (!insert) {
      if (last_update) {
        print "UPDATE END " last_update
      }
      print "INSERT START " $10
      #print $0
    }
    last_insert=$10
    insert=1
    update=0
  }
}
/desc: UPDATE /{
  if (start) {
    if (!update) {
      print "INSERT END " last_insert
      print "UPDATE START " $10
      #print $0
    }
    last_update=$10
    update=1
    insert=0
  }
}
