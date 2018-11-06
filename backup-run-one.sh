#!/bin/bash


sleep_until_finish_starting() {
  local starting=$(docker ps --filter 'health=starting' -q)
  while [ "$starting" != "" ]; do
    echo "Some containers are still starting at $(date), sleeping for $SLEEP_INIT"  2>&1 | tee  /var/log/backup.log
    sleep $SLEEP_INIT
    starting=$(docker ps --filter 'health=starting' -q)
  done
} 

sleep_until_finish_starting
/run-one-1.17/run-one /usr/local/bin/backup-process.sh
