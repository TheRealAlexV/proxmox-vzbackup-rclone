#!/bin/bash
# ./vzbackup-rclone.sh rehydrate YYYY/MM/DD file_name_encrypted.bin

############ /START CONFIG
drive="gd-backup_crypt"
dumpdir="/mnt/pve/pvebackups01/dump" # Set this to where your vzdump files are stored
MAX_AGE=3 # This is the age in days to keep local backup copies. Local backups older than this are deleted.
MAX_CLOUD_AGE=31 # This is the age in days to keep cloud backup copies. Cloud backups older than this are deleted
############ /END CONFIG

_bdir="$dumpdir"
rcloneroot="$dumpdir/rclone"
timepath="$(date +%Y-%m-%d)"
rclonedir="$rcloneroot/$timepath"
COMMAND=${1}
rehydrate=${2} #enter the date you want to rehydrate in the following format: YYYY/MM/DD
if [ ! -z "${3}" ];then
        CMDARCHIVE=$(echo "/${3}" | sed -e 's/\(.bin\)*$//g')
fi
if [ -z ${TARGET+x} ]; then 
    tarfile=${TARFILE}
else
    tarfile=${TARGET}
fi
exten=${tarfile#*.}
filename=${tarfile%.*.*}

if [[ ${COMMAND} == 'rehydrate' ]]; then
    #echo "Please enter the date you want to rehydrate in the following format: YYYY/MM/DD"
    #echo "For example, today would be: $timepath"
    #read -p 'Rehydrate Date => ' rehydrate
    rclone --config /root/.config/rclone/rclone.conf \
    --drive-chunk-size=32M copy $drive:/$rehydrate$CMDARCHIVE $dumpdir \
    -v --stats=60s --transfers=16 --checkers=16
fi

if [[ ${COMMAND} == 'job-start' ]]; then
    echo "Deleting backups older than $MAX_AGE days."
    find $dumpdir -type f -mtime +$MAX_AGE -exec /bin/rm -f {} \;
fi

if [[ ${COMMAND} == 'backup-end' ]]; then
    echo "Backing up $tarfile to remote storage"
    echo "rcloning $rclonedir"
    
    rclone --config /root/.config/rclone/rclone.conf \
    --drive-chunk-size=32M copy $tarfile $drive:/$timepath \
    -v --stats=60s --transfers=16 --checkers=16
fi

if [[ ${COMMAND} == 'job-end' ||  ${COMMAND} == 'job-abort' ]]; then
    echo "Backing up main PVE configs"
    _tdir=${TMP_DIR:-/var/tmp}
    _tdir=$(mktemp -d $_tdir/proxmox-XXXXXXXX)
    function clean_up {
        echo "Cleaning up"
        rm -rf $_tdir
    }
    trap clean_up EXIT
    _now=$(date +%Y-%m-%d.%H.%M.%S)
    _HOSTNAME=$(hostname -f)
    _filename1="$_tdir/proxmoxetc.$_now.tar"
    _filename2="$_tdir/proxmoxpve.$_now.tar"
    _filename3="$_tdir/proxmoxroot.$_now.tar"
    _filename4="$_tdir/proxmox_backup_"$_HOSTNAME"_"$_now".tar.gz"

    echo "Tar files"
    # copy key system files
    tar --warning='no-file-ignored' -cPf "$_filename1" /etc/.
    tar --warning='no-file-ignored' -cPf "$_filename2" /var/lib/pve-cluster/.
    tar --warning='no-file-ignored' -cPf "$_filename3" /root/.

    echo "Compressing files"
    # archive the copied system files
    tar -cvzPf "$_filename4" $_tdir/*.tar

    # copy config archive to backup folder
    cp -v $_filename4 $_bdir/

    echo "rcloning $_filename4"

    rclone --config /root/.config/rclone/rclone.conf \
    --drive-chunk-size=32M move $_filename4 $drive:/$timepath \
    -v --stats=60s --transfers=16 --checkers=16

    rclone --config /root/.config/rclone/rclone.conf \
      delete --min-age ${MAX_CLOUD_AGE}d $drive:backups/
fi
