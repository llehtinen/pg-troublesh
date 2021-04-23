#!/bin/bash
PRINT_DATE=0
SLEEP=0.05

usage() { echo "Usage: $0 [-s <seconds>] [-d]" 1>&2; exit 1; }

while getopts ":s:d" o; do
    case "${o}" in
        s)
            SLEEP=${OPTARG}
            ;;
        d)
            PRINT_DATE=1
            ;;
        *)
            usage
            ;;
    esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
WAL_DIR="$( cd "$DIR/../pg_data/pg_wal" &> /dev/null && pwd)"
PID="$(ps aux |grep osxfs |grep -v grep |awk '{print $2}')"
if [ ! -n "$PID" ]; then
  echo "NO PID FOUND"
  exit 1
fi
#echo "osxfs PID $PID"
IGNORE_FDS=$(echo $(lsof +D $WAL_DIR |grep pg_wal |awk '{print $4}')| sed 's/ /|/g')
while true
do
    WAL=$(lsof -p $PID |grep "$WAL_DIR" |grep -Ev " \d{2,}u |$IGNORE_FDS" |awk '{print $NF " is open"}')
    if [ -n "$WAL" ]; then
      MSG=$(basename $WAL)
    else
      MSG="NO WAL OPEN"
    fi
    if [ "$MSG" != "$PRINTED_MSG" ]; then
      if [ $PRINT_DATE = 1 ]; then
        echo $(date +"%H:%M:%S") " " $MSG
      else
        echo $MSG
      fi
      PRINTED_MSG=$MSG
    fi
    sleep $SLEEP
done


