#!/bin/bash

###################################################################
#Script Name:	Dump and rsync to remote storage
#Description:	Create Dump from dockerized postgresql, Upload The Dump To The Remote Storage Using Rsync
###################################################################

# Variables
DB_NAME=mydb
DB_USER=myuser
DIR=/opt/backup
CLOCK=0045
FILE=$DIR/$DB_NAME-$(date +"%Y-%m-%d")-$CLOCK.dump
REMOTE_STORAGE='/storage/mydb-db/'
STORAGE_ADDR=172.31.85.201
USER_IN_STORAGE=mydb
SYSLOG_FACILITY_NAME=local0
CONTAINER_NAME=postgres
BKP_DATE=$(date +"%Y-%m-%d")
LOGGER_TAG=mydb-dump

# Functions
database-dump() {
    dump_state=$(/usr/bin/time -f %e -o /tmp/container_dump_time docker exec $CONTAINER_NAME pg_dump -U$DB_USER --file=/tmp/$DB_NAME-$BKP_DATE.dump --format=c --no-owner --no-acl  $DB_NAME) /dev/null 2>&1
    if [[ $dump_state -eq 0 ]]
    then
        docker cp $CONTAINER_NAME:/tmp/$DB_NAME-$BKP_DATE.dump $DIR
        docker exec $CONTAINER_NAME rm /tmp/$DB_NAME-$BKP_DATE.dump
	mv $DIR/$DB_NAME-$BKP_DATE.dump $FILE
        logger -p local0.info -t "$LOGGER_TAG" "creating dump for $DB_NAME-$BKP_DATE.dump was OK."
    else
        logger -p local0.info -t "$LOGGER_TAG" "Error: creating dump for $DB_NAME-$BKP_DATE.dump was FAIL !"
        exit 1;
    fi
}

remove-old-backups-locally() {
    rm -f $DIR/$DB_NAME-$(date +"%Y-%m-%d" -d '-2 days')-$CLOCK.dump
    if [ $? -ne 0 ]; then
        logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rm" "Error: Remove the old backup file Failed !"
        exit 1
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rm" "Remove the old backup file finished."
}

upload-to-storage() {
    rsync -avzh --progress $FILE $USER_IN_STORAGE@$STORAGE_ADDR:$REMOTE_STORAGE
    if [ $? -ne 0 ]; then
        logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rsync" "Error: copy the backup to remote storage Failed !"
        exit 1
    fi
    logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rsync" "Copy to remote storage finished."
}

# Main
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-dump" "######## Start $DB_NAME Dump Script ########"
logger -p local0.info -t "$LOGGER_TAG" "Dump Started"
database-dump
logger -p local0.info -t "$LOGGER_TAG" "Dump Finished"
if [[ -f /tmp/container_dump_time ]]
then
    real_time=$(cat /tmp/container_dump_time)
    logger -p local0.info -t "$LOGGER_TAG" "The Dump Time Duration Is: $real_time "
    rm -rf /tmp/container_dump_time
else
    logger -p local0.info -t "$LOGGER_TAG" "Warning: There is no file to show dump duration "
fi
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rsync" "Copy To Storage Started."
upload-to-storage
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rsync" "Copy To Storage Finished."
remove-old-backups-locally
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rsync" "####### Finish $DB_NAME Dump Script ########"

# Dump commands:
# docker exec $CONTAINER_NAME pg_dump -U$DB_USER --file=$FILE --format=c --no-owner --no-acl  $DB_NAME
# docker cp $CONTAINER_NAME:$FILE .
# docker exec $CONTAINER_NAME rm $FILE
