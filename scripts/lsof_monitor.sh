#!/bin/bash

PID="$(ps aux |grep osxfs |grep -v grep |awk '{print $2}')"
if [ ! -n "$PID" ]; then
  echo "NO PID FOUND"
  exit 1
fi
#echo "osxfs PID $PID"

IGNORE_FDS=$(echo $(lsof -p $PID |grep pg_wal |awk '{print $4}')| sed 's/ /|/g')
#echo "Ignoring FDs $IGNORE_FDS"

while true
do
    WAL=$(lsof -p $PID |grep pg_wal |grep -Ev " \d{2,}u "|grep -Ev $IGNORE_FDS |awk '{print $NF " is open"}')
    if [ -n "$WAL" ]; then
      MSG=$(basename $WAL)
    else
      MSG="NO WAL OPEN"
    fi
    if [ "$MSG" != "$PRINTED_MSG" ]; then
#      echo $(date +"%H:%M:%S") " " $MSG
      echo $MSG
      PRINTED_MSG=$MSG
    fi
    sleep 0.05
done


