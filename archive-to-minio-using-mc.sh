#!/bin/bash

# requirements:
# mc command as minio client
# create an Alias for your bucket in mc command (https://min.io/docs/minio/linux/reference/minio-mc.html)

# variables
MC_ALIAS=myminio
MC_BUCKET=mybucket
MC_BINARY_PATH=/opt/minio-binaries
BKP_LOCAL_PATH=/opt/backup
BKP_TODAY_DATE=$(date --iso)
BKP_OLD_DATE=$(date --iso -d '7 days ago')

# functions
function check_connection {
	$MC_BINARY_PATH/mc ls $MC_ALIAS/$MC_BUCKET/	
	if [ $? -ne 0 ]; then
		logger -p local1.info -t "Connection Failed" "Error: $MC_BUCKET is not reachable, connection FAILED."
		exit 1
	fi
	logger -p local1.info -t "Connected" "$MC_BUCKET is reachable."
}

function check_today_backup {
	find $BKP_LOCAL_PATH -maxdepth 1 -type d -name $BKP_TODAY_DATE | grep .
	if [ $? -ne 0 ]; then
                logger -p local1.info -t "Backup Not Found" "Error: Today backup not found!"
                exit 1
        fi
	logger -p local1.info -t "Backup Exists" "Today backup file exists."
}

function remove_old_backup_locally {
	rm -rfv $BKP_LOCAL_PATH/$BKP_OLD_DATE
	logger -p local1.info -t "Clean Backups" "Backup $BKP_OLD_DATE was removed locally."
}

function remove_old_backup_storage {
	$MC_BINARY_PATH/mc rm --recursive --force $MC_ALIAS/$MC_BUCKET/$BKP_OLD_DATE/
	logger -p local1.info -t "Free Storage" "Backup $MC_BUCKET/$BKP_OLD_DATE was removed from $MC_ALIAS."
}

function send_today_backup {
	$MC_BINARY_PATH/mc cp --recursive $BKP_LOCAL_PATH/$BKP_TODAY_DATE $MC_ALIAS/$MC_BUCKET/
	logger -p local1.info -t "Backup Sent" "Backup $BKP_TODAY_DATE sent to $MC_ALIAS/$MC_BUCKET/ successfully."
}

# main
check_today_backup
check_connection
remove_old_backup_storage
send_today_backup
remove_old_backup_locally
