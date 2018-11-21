#!/bin/bash
#set -x #Display commands and their arguments as they are executed.
#set -v #Display shell input lines as they are read.

# these GLOBAL variables should be set in docker-compose.yml file as environment variables.

#GLOBAL_VARIABLES
#USED_PERCENTAGE_THRESHOLD when disk space % > threshold send email
#FROM email of sender
#TO email to receive notification when disk space % > threshold
#SMTP_USER gmail user (without @gmail.com) 
#SMTP_PASS   gmail password
#LOG_SIZE  nbr of lines to keep in backup-client.log

#these GLOBAL variables are calculated
setNODE_HOSTNAME() {
  #assumes the container has volume "/etc:/usr/local/data"
  NODE_HOSTNAME=$(cat /usr/local/data/hostname 2> /dev/null)
}
setNODE_HOSTNAME

#functions
setUSED_PERCENTAGE_STR() {
#  usedStr=$(df --output=pcent . ) not supported by all versions of df :(
  usedStr=$(df . | grep "\d%")
  usedArray=($usedStr)
  USED_PERCENTAGE_STR=${usedArray[4]}
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
if (( $USED_PERCENTAGE > $USED_PERCENTAGE_THRESHOLD )) ; then
  rm /var/log/email.log
  echo "*********************************************"  2>&1 | tee -a  /var/log/diskusage.log /var/log/email.log
  echo "Low disk space reached on $NODE_HOSTNAME !!!!"  2>&1 | tee -a  /var/log/diskusage.log /var/log/email.log
  echo "*********************************************"  2>&1 | tee -a  /var/log/diskusage.log /var/log/email.log
  df -h  .  2>&1 | tee -a  /var/log/email.log 
  cat /var/log/email.log | sendEmail -f $FROM -t $TO -u Low disk space reached on $NODE_HOSTNAME  -s smtp.gmail.com:587 -o tls=auto -xu $SMTP_USER -xp $SMTP_PASS
fi
df -h .  2>&1 | tee -a  /var/log/diskusage.log

echo "Ending check disk space usage at $(date)"  2>&1 | tee -a  /var/log/diskusage.log

keep_only_log_tail

