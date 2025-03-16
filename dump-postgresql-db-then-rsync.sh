#!/bin/bash

###################################################################
#Script Name:	Dump and rsync to remote storage
#Description:	Create Dump, Upload The Dump To The Remote Storage Using Rsync
###################################################################

### Variables
DB_NAME=mydatabase
DB_USER=myuser
DIR=/db_backup
CLOCK=0030
FILE=$DIR/$DB_NAME-$(date +"%Y-%m-%d")-$CLOCK.dump
REMOTE_STORAGE='/storage/backup-db/'
STORAGE_ADDR=172.31.80.190
USER_IN_STORAGE=myuser
SYSLOG_FACILITY_NAME=local0

### Functions
database-dump() {
    dump_state=$(/usr/bin/time -f %e -o /tmp/dump_time pg_dump -U$DB_USER --file=$FILE --format=c --no-owner --no-acl  $DB_NAME) > /dev/null 2>&1
    if [[ $dump_state -eq 0 ]]
    then
        logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-dump" "creating dump for $DB_NAME-$(date +"%Y-%m-%d")-$CLOCK.dump was OK."
    else
        logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-dump" "creating dump for $DB_NAME-$(date +"%Y-%m-%d")-$CLOCK.dump was FAIL !"
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

### Main
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-dump" "######## Start $DB_NAME Dump Script ########"
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-dump" "Dump Started."
database-dump
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-dump" "Dump Finished."
if [[ -f /tmp/dump_time ]]
then
    real_time=$(cat /tmp/dump_time)
    logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-Dump-Time" "The Dump Time Duration Is: $real_time "
    rm -rf /tmp/dump_time
else
    logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-Dump-Time" "There Is No File To Show Dump Duration (Failure) "
fi
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rsync" "Copy To Storage Started."
upload-to-storage
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rsync" "Copy To Storage Finished."
remove-old-backups-locally
logger -p $SYSLOG_FACILITY_NAME.info -t "$DB_NAME-rsync" "####### Finish $DB_NAME Dump Script ########"

