#!/bin/bash

# variables
MOUNT_PATH='/mnt/app-backup'
REMOTE_LOCATION='/mnt/app-backup/myapp'
LOCAL_LOCATION='/opt/backup'
SMB_ADDR='//mysmb.cloud.com/folder'
SMB_USER='myuser'
SMB_PASSWD='StrongPassword'
SYSLOG_FACILITY_NAME='local6'
DB_NAME=mydatabase
DB_USER=mydbuser
DB_PASS='StrongPassword'
APP_FILES_LOCATION='/opt/myapp-docker-compose/app_storage/'
TIME=$(date +"%Y-%m-%d-%s")
OLD_BACKUPS_TIME=$(date +"%Y-%m-%d" -d '-14 days')

# functions
mount_smb_storage() {
    mount -t cifs $SMB_ADDR $MOUNT_PATH --verbose -o user=$SMB_USER,password=$SMB_PASSWD
    if [ $? -ne 0 ]; then
        logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Error: Failed to mount $SMB_ADDR"
        exit 1   
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "smb storage mounted successfully."
}
umount_smb_storage() {
    umount $MOUNT_PATH
    if [ $? -ne 0 ]; then
    	logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Error: smb storage umount Failed!"
	    exit 1
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "smb storage umounted successfully."
}
dump_database() {
    docker exec myapp-mysql bash -c "mysqldump -u$DB_USER -p'$DB_PASS' $DB_NAME" > $LOCAL_LOCATION/myapp-db-backup-$TIME.sql
    if [ $? -ne 0 ]; then
    	logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Error: mysqldump Failed!"
	    umount_smb_storage
        exit 1
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "mysqldump executed successfully."
}
copy_app_files() {
    mkdir $LOCAL_LOCATION/myapp-files-$TIME
    cp -ar $APP_FILES_LOCATION $LOCAL_LOCATION/myapp-files-$TIME
    if [ $? -ne 0 ]; then
    	logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Error: copy app files Failed!"
	    umount_smb_storage
        exit 1
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Copy app files done."
}
compress_files() {
    cd $LOCAL_LOCATION
    tar -zcf myapp-backup-$TIME.tar.gz myapp-files-$TIME myapp-db-backup-$TIME.sql
    if [ $? -ne 0 ]; then
    	logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Error: compressing files Failed!"
	    umount_smb_storage
        exit 1
    fi
    rm -rf myapp-files-$TIME myapp-db-backup-$TIME.sql
    logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Compressing files done."
}
transfer_to_smb() {
    cp -rvf $LOCAL_LOCATION/myapp-backup-$TIME.tar.gz $REMOTE_LOCATION
    if [ $? -ne 0 ]; then
    	logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Error: copy the backup to smb storage Failed!"
	    umount_smb_storage
        exit 1
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Copy to smb finished."
}
remove_old_local_bkps() {
    find $LOCAL_LOCATION -type f -ctime +22 -exec rm {} +
    if [ $? -ne 0 ]; then
    	logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Error: removing old local backups Failed!"
	    umount_smb_storage
        exit 1
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Old local backups removed."
}
remove_old_remote_bkps() {
    find $REMOTE_LOCATION -type f -ctime +10 -exec rm {} +
    if [ $? -ne 0 ]; then
        logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Error: removing old remote backups Failed!"
        umount_smb_storage
        exit 1
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "Old remote backups removed."
}

# main
logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "########## Backuping myapp started ... ##########"
mount_smb_storage
dump_database
copy_app_files
compress_files
transfer_to_smb
remove_old_local_bkps
remove_old_remote_bkps
umount_smb_storage
logger -p $SYSLOG_FACILITY_NAME.info -t "myapp-backup" "########## Backuping myapp finished ... ##########"

