#!/bin/bash

# these GLOBAL variables should be set in docker-compose.yml file as environment variables.

#GLOBAL_VARIABLES
USED_PERCENTAGE_THRESHOLD=75
LOG_SIZE=10000

#these GLOBAL variables are calculated

setUSED_PERCENTAGE_STR() {
  usedStr=$(df --output=pcent . )
  usedArray=($usedStr)
  USED_PERCENTAGE_STR=${usedArray[1]}
}

setUSED_PERCENTAGE() {
  setUSED_PERCENTAGE_STR
  USED_PERCENTAGE="${USED_PERCENTAGE_STR::-1}" 
}

keep_only_log_tail() {
  cp /var/log/diskusage.log /var/log/diskusage.tmp
  tail -n $LOG_SIZE /var/log/diskusage.tmp >> /var/log/diskusage.log
  rm /var/log/diskusage.tmp
}


#main
touch /var/log/diskusage.log
echo "Starting check disk space usage at $(date)"  2>&1 | tee -a /var/log/diskusage.log

setUSED_PERCENTAGE
echo $USED_PERCENTAGE
if (( $USED_PERCENTAGE > $USED_PERCENTAGE_THRESHOLD )) ; then
  echo "**************************"  2>&1 | tee -a  /var/log/diskusage.log
  echo "*Low disk space reached!!*"  2>&1 | tee -a  /var/log/diskusage.log
  echo "**************************"  2>&1 | tee -a  /var/log/diskusage.log
fi
df .  2>&1 | tee -a  /var/log/diskusage.log

echo "Ending check disk space usage at $(date)"  2>&1 | tee -a  /var/log/diskusage.log

keep_only_log_tail
