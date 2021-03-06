#!/bin/bash

# these GLOBAL variables should be set in docker-compose.yml file as environment variables.
#FTP_SERVER ip of ftp-server to send backups to
#FTP_USER userid for ftp loging
#FTP_PASSWD passwd for ftp loging
#SLEEP_INIT how long to sleep waiting for containers to fully start
#SLEEP how long to sleep before taking another backups
#LOG_SIZE  nbr of lines to keep in backup-client.log

# GLOBAL variables
TMPDIR=${TMPDIR:-/tmp}
BACKUPDIR=""

#these GLOBAL variables are calculated
setNODE_HOSTNAME() {
  #assumes the container has volume "/etc:/usr/local/data"
  NODE_HOSTNAME=$(cat /usr/local/data/hostname 2> /dev/null)
}
setNODE_HOSTNAME

setNODE_IP() {
  NODE_IP=$(docker info --format '{{.Swarm.NodeAddr}}')
}
setNODE_IP

setSTACK_NAMESPACE() {
  STACK_NAMESPACE=$(docker inspect --format '{{index .Config.Labels "com.docker.stack.namespace"}}' $(hostname) 2> /dev/null)
}
setSTACK_NAMESPACE

setCONTAINERS(){
  #running containers for this namespace on this node
  CONTAINERS=($(docker ps --filter name="$STACK_NAMESPACE" -q))
}

setCONTAINER_VOLUMES() { #$1 
  CONTAINER_VOLUMES_destinations=()
  CONTAINER_VOLUMES_names=()
  local ps=$1
  local len=$(docker inspect $ps --format "{{(len .Mounts)}}")
  local c=0
  local fmt=""
  local inspect=""
  while [ $c -lt $len ]; do 
    fmt="{{(index .Mounts $c).Type}} {{(index .Mounts $c).Destination}} {{(index .Mounts $c).Name}} $fmt" #map sequence not garanted over multiple calls
    let c=$c+1
  done
  inspect=($(docker inspect $ps --format "$fmt"))
  len=${#inspect[@]}
  c=0
  while [ $c -lt $len ]; do
    local item=${inspect[$c]}    
    if [ "$item" == "volume" ]; then
      let c=$c+1
      local volumeDest=${inspect[$c]}
      let c=$c+1
      local volumeName=${inspect[$c]}
      CONTAINER_VOLUMES_destinations+=($volumeDest)
      CONTAINER_VOLUMES_names+=($volumeName)
    fi
    let c=$c+1 
  done
}

backup_gitlab_data_volume() {
  #it is not needed to backup everything in the data volume, gitlab provide a function to perform this, so we just ftp what it produces
  local container=$1
  local volumeName=$2
  local volumeDest=$3
  local tmpdir=$(mktemp -d $TMPDIR/$volumeName.XXXXXXXXX)
  local  tarfileNew=$TMPDIR/$volumeName.tar
  echo "  $volumeName.tar"  2>&1 | tee -a /var/log/backup.log  
  docker exec -t $container gitlab-rake gitlab:backup:create 2>&1 | tee -a /var/log/backup.log #the tee is to duplicate the outs to a file for loggin
  docker cp $container:$volumeDest/backups $tmpdir   
  local tmpNames=($(ls -1 $tmpdir/backups|sort -r))
  local tarfile="$tmpdir/backups/${tmpNames[0]}"
  mv  $tarfile $tarfileNew   
  copy_file_to_ftp $tarfileNew
  rm -rf $tmpdir
  rm $tarfileNew
} 
 
backup_volume() {
  #tar the content of the volume and ftp it
  local container=$1
  local volumeName=$2
  local volumeDest=$3
  local tmpdir=$(mktemp -d $TMPDIR/$volumeName.XXXXXXXXX)
  local tarfile=$TMPDIR/$volumeName.tgz
  echo "  $(basename $tarfile)"  2>&1 | tee -a /var/log/backup.log
  docker cp $container:$volumeDest $tmpdir
  pushd $tmpdir > /dev/null
  tar -czf $tarfile .
  copy_file_to_ftp $tarfile
  popd > /dev/null
  #cleanup
  rm -r $tmpdir
  rm $tarfile
}

make_dir_in_ftp() {
  lftp $FTP_SERVER -u $FTP_USER,$FTP_PASSWD << EOT
    mkdir $BACKUPDIR
    close
EOT
}

copy_file_to_ftp() { #dir_file_name
  local dirN=$(dirname $1)
  local fileN=$(basename $1)
  pushd $dirN > /dev/null
  lftp $FTP_SERVER -u $FTP_USER,$FTP_PASSWD << EOT
    user $FTP_USER $FTP_PASSWD
    cd $BACKUPDIR
    put $fileN
    close  
EOT
  popd > /dev/null
 }
  
create_backups() {
  BACKUPDIR=$NODE_HOSTNAME.$(date +%Y-%m-%d_%H_%M_%S-%Z)
  make_dir_in_ftp
  echo "Started create_backups on $NODE_HOSTNAME at $(date)"  2>&1 | tee  /var/log/backup.log
  setCONTAINERS
  for container in ${CONTAINERS[@]}; do
    setCONTAINER_VOLUMES $container
    local c=0
    for volumeDest in "${CONTAINER_VOLUMES_destinations[@]}"; do
      local  volumeName=${CONTAINER_VOLUMES_names[$c]}
      if [ $volumeDest == "/var/opt/gitlab" ]; then
        backup_gitlab_data_volume $container $volumeName $volumeDest
      else
        backup_volume $container $volumeName $volumeDest
      fi
      let c=$c+1
    done
  done
  echo "DONE with backups at $(date)!"  2>&1 | tee -a /var/log/backup.log  #althought the backups are truly done when the ftp of the log is done, we need to log before we ftp or lose the echo
  copy_file_to_ftp /var/log/backup.log
  cat /var/log/backup.log >> /var/log/backup-client.log
  rm /var/log/backup.log
}

create_backups
