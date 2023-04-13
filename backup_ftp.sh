#!/bin/bash

# variables
FTP_PASS=$FTP_STORAGE_PASS
REMOVE_OUTPUT=0

# help
function instruction {
    cat << EOL
Description:
  create a tar.gz file from a given directory,
  then upload it to a ftp backup storage.
Usage: $0 [OPTIONS] -d <input_directory> -o <output_file.tar.gz> -u <ftp_user> -f <ftp_server_address>
Options:
  -p <ftp_password> : or use FTP_STORAGE_PASS environment variable.
  -r : remove the output tar.gz file from <output_directory> after a successful upload to the ftp server.
  -h : show help
EOL
echo
}

# read options
if [[ $# -eq 0 ]]; then
    instruction
    exit
fi

while [[ $# -ne 0 ]]; do
    case $1 in
        -h)
            instruction
            exit 0
            ;;
        -r)
            REMOVE_OUTPUT=1
            shift
            ;;
        -d)
            if [[ ! -d "$2" ]]; then
                echo "Error: -d needs a directory path"
                instruction
                exit 1
            fi
            INPUT_DIR=$2
            shift 2
            ;;
        -o)
            if [ -z "$2" ]; then
                echo "Error: -o needs a directory path"
                instruction
                exit 1
            fi
            OUT_FILE=$2
            shift 2
            ;;
        -u)
            if [ -z "$2" ]; then
                echo "Error: -u needs a username"
                instruction
                exit 1
            fi
            USERNAME=$2
            shift 2
            ;;
        -f)
            if [ -z "$2" ]; then
                echo "Error: -f needs a ftp server address"
                instruction
                exit 1
            fi
            SERVER=$2
            shift 2
            ;;
        -p)
            if [ -z "$2" ]; then
                echo "Error: -p needs a ftp server password"
                echo "or use FTP_STORAGE_PASS environment variable"
                instruction
                exit 1
            fi
            FTP_PASS=$2
            shift 2
            ;;
        *)
            echo "Error: unexpected argument!"
            instruction
            exit 1
            ;;
    esac
done

if [ -z "$INPUT_DIR" ] || [ -z "$OUT_FILE" ] || [ -z "$USERNAME" ] || [ -z "$SERVER" ]; then
    echo "Error: insufficient arguments!"
    instruction
    exit 1
fi

# check disk space for creating the tar.gz file
INPUT_SIZE=$(du -s $INPUT_DIR | awk '{print $1}')
FREE_SPACE=$(df / | sed -n '2 p' | awk '{print $4}')
if [[ "$INPUT_SIZE" -ge "$FREE_SPACE" ]]; then
    echo "Error: insufficient free disk space!"
    exit 1
fi
echo "Free disk space [OK]"

# check connection to ftp server
echo 'exit' | ftp ftp://$USERNAME:$FTP_PASS@$SERVER/ > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to ftp server"
    exit 1
fi
echo "FTP server connection [OK]"

# create tar.gz file
tar -zcf $OUT_FILE $INPUT_DIR
echo "tar.gz file creation [OK]"

# upload to ftp server
OUT_FILE_PATH=$(dirname $OUT_FILE)
OUT_FILE_NAME=$(basename $OUT_FILE)
cd $OUT_FILE_PATH
echo "Uploading to ftp server..."
ftp -n $SERVER << EOL
quote USER $USERNAME
quote PASS $FTP_PASS
binary
put $OUT_FILE_NAME
quit
EOL
echo "Uploading to ftp server [OK]"

# delete tar.gz file after a successful upload
if [[ $REMOVE_OUTPUT -eq 1 ]]; then
    rm -f $OUT_FILE
    echo "Removing local tar.gz file [OK]"
fi
echo "Done!"
