#!/bin/bash

# these GLOBAL variables should be set in docker-compose.yml file as environment variables.
#FTP_SERVER ip of ftp-server to send backups to
#FTP_USER userid for ftp loging
#FTP_PASSWD passwd for ftp loging
#SLEEP_INIT how long to sleep waiting for containers to fully start
#SLEEP how long to sleep before taking another backups
#LOG_SIZE  nbr of lines to keep in backup-client.log

# GLOBAL variables

setNODE_IP() {
  NODE_IP=$(docker info --format '{{.Swarm.NodeAddr}}')
}
setNODE_IP

sleep_until_finish_starting() {
  local starting=$(docker ps --filter 'health=starting' -q)
  while [ "$starting" != "" ]; do
    echo "Some containers are still starting at $(date), sleeping for $SLEEP_INIT"  2>&1 | tee  /var/log/backup.log
    sleep $SLEEP_INIT
    starting=$(docker ps --filter 'health=starting' -q)
  done
} 
 
keep_only_log_tail() {
  cp /var/log/backup-client.log /var/log/backup-client.tmp
  tail -n $LOG_SIZE /var/log/backup-client.tmp > /var/log/backup-client.log
  rm /var/log/backup-client.tmp
}

sleep_until_finish_starting
while true; do  #loop infinitely to produce backups 
  if [ "$NODE_IP" != "$FTP_SERVER" ]; then
    /run-one-1.17/run-one  /usr/local/bin/backup-process.sh
  fi
  keep_only_log_tail
  /run-one-1.17/run-one  /usr/local/bin/diskusage.sh
  sleep $SLEEP
done
