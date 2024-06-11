#!/bin/bash

###################################################################
#Description:	Create Dump from dockerized postgresql, Upload The Dump To SMB
###################################################################

# Variables
DB_NAME=mydatabase
DB_USER=myuser
MOUNT_POINT=/mnt
SMB_PATH=/mnt/mydatabase-db
SMB_ADDR=//mysmb.local
SMB_USER='smb_user'
SMB_PASS='smb_pass'
BKP_DIR=/opt/backup
BKP_DATE=$(date +"%Y-%m-%d")
BKP_KEEP_UNTIL=$(date +"%Y-%m-%d" -d '-2 days')
BKP_FILE=$BKP_DIR/$DB_NAME-$BKP_DATE.dump
CONTAINER_NAME=postgres
LOGGER_TAG=mydatabase-dump

# Functions
db_dump() {
    dump_state=$(/usr/bin/time -f %e -o /tmp/container_dump_time docker exec $CONTAINER_NAME pg_dump -U$DB_USER --file=/tmp/$DB_NAME-$BKP_DATE.dump --format=c --no-owner --no-acl  $DB_NAME) /dev/null 2>&1
    if [[ $dump_state -eq 0 ]]
    then
        docker cp $CONTAINER_NAME:/tmp/$DB_NAME-$BKP_DATE.dump $BKP_DIR
        docker exec $CONTAINER_NAME rm /tmp/$DB_NAME-$BKP_DATE.dump
        logger -p local0.info -t "$LOGGER_TAG" "######## creating dump for $DB_NAME-$BKP_DATE.dump was OK ########"
    else
        logger -p local0.info -t "$LOGGER_TAG" "######## Error: creating dump for $DB_NAME-$BKP_DATE.dump was FAIL ########"
        exit 1;
    fi
}

dump_to_smb() {
    mount -t cifs $SMB_ADDR $MOUNT_POINT --verbose -o user=$SMB_USER,password=$SMB_PASS
    cp -rvf $BKP_DIR/$DB_NAME-$BKP_DATE.dump $SMB_PATH
    if [[ $? -eq 0 ]]
    then
        logger -p local0.info -t "$LOGGER_TAG" "######## Copy $DB_NAME-$BKP_DATE.dump to SMB storage was OK"
        rm -f $BKP_DIR/$DB_NAME-$BKP_KEEP_UNTIL.dump
        umount $MOUNT_POINT
    else
	    logger -p local0.info -t "$LOGGER_TAG" "######## Copy $DB_NAME-$BKP_DATE.dump to SMB storage was Fail"
	    umount $MOUNT_POINT
	    exit 1;
    fi
}

# Main
logger -p local0.info -t "$LOGGER_TAG" "######## Start Dump ########"
db_dump
logger -p local0.info -t "$LOGGER_TAG" "######## Finish Dump ########"
if [[ -f /tmp/container_dump_time ]]
then
    real_time=$(cat /tmp/container_dump_time)
    logger -p local0.info -t "$LOGGER_TAG" "######## The Dump Time Duration Is: $real_time  ########"
    rm -rf /tmp/container_dump_time
else
    logger -p local0.info -t "$LOGGER_TAG" "######## Warning: There is no file to show dump duration  ########"
fi
logger -p local0.info -t "$LOGGER_TAG" "######## Start SMB Copy ########"
dump_to_smb
logger -p local0.info -t "$LOGGER_TAG" "######## Finish SMB Copy ########"
