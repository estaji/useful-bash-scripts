#!/bin/bash

# Variables
REMOVER_DIR="/usr/share/nginx/statics/"
REMOVER_PAST_DAYS=20
REMOVER_TODAY=$(date +%F)

# Functions
check_dir_exists() {
    if [ ! -d "$REMOVER_DIR" ]; then
        echo "$REMOVER_DIR does not exist."
        logger -p local1.info -t "check dir exists" "$REMOVER_DIR does not exist."
        exit 1
    fi
}
find_and_delete() {
    find $REMOVER_DIR -type f -mtime +$REMOVER_PAST_DAYS -exec rm -vf {} \; | xargs logger -p local1.info -t "deleted"
}

# Main
check_dir_exists
logger -p local1.info -t "start find and delete" "############ Start Date: $REMOVER_TODAY ############"
find_and_delete
logger -p local1.info -t "end find and delete" "############ End Date: $REMOVER_TODAY ############"
