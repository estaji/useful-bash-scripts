#!/bin/bash

# Create incremental backup on each execution (for example by a cronjob)
# And create full (tar) backup on specific Day Of Week and Hour
# Destination is a SMB server

# Variables
BKP_SMB_HOST=server-adress.com
BKP_SMB_PATH=directory
BKP_SMB_USER=myuser
BKP_SMB_PASS=mypass
BKP_MNT_POINT=/mnt/mount-point
BKP_RSYNC_OPT="-av"
BKP_RSYNC_SRC="source-of-data"
BKP_DOW=5
BKP_HOUR=2

# Functions
connect_smb() {
    mount -t cifs //$BKP_SMB_HOST/$BKP_SMB_PATH $BKP_MNT_POINT --verbose -o user=$BKP_SMB_USER,password=$BKP_SMB_PASS
}
disconnect_smb() {
    umount $BKP_MNT_POINT
}
do_rsync() {
    rsync $BKP_RSYNC_OPT $BKP_RSYNC_SRC $BKP_MNT_POINT
}
current_date_time() {
    # DOW; (1..7), 1 is Monday
    BKP_CURRENT_DOW=$(date +%u)
    BKP_CURRENT_HOUR=$(date +"%H")
    BKP_CURRENT_DATE=$(date +%F)
}
create_tar() {
    tar czf $BKP_MNT_POINT/full-backup-$BKP_CURRENT_DATE.tar.gz --exclude='*.tar.gz' $BKP_MNT_POINT/
}

# Main
connect_smb
if [[ "$?" -ne 0 ]]; then
    logger -p local0.info -t "backup mount smb" "### mounting $BKP_SMB_HOST FAILED!"
    exit 1
fi
current_date_time
logger -p local0.info -t "backup rsync start" "### rsync starting..."
do_rsync
if [[ "$?" -eq 1 ]]; then
    logger -p local0.info -t "backup rsync failed" "### rsync FAILED!"
    disconnect_smb
    exit 1
fi
logger -p local0.info -t "backup rsync done" "### rsync finished."
if [[ $BKP_CURRENT_DOW -eq $BKP_DOW ]] && [[ $BKP_CURRENT_HOUR -eq $BKP_HOUR ]]; then
    logger -p local0.info -t "backup tar start" "### today is full backup day, creating tar file..."
    create_tar
    logger -p local0.info -t "backup tar done" "### full-backup-$BKP_CURRENT_DATE.tar.gz is created."
fi
disconnect_smb
