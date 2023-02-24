#!/bin/bash

# variables
REGEX_NUM='^[0-9]+$'
OPTIONS_ARGS=0
TRY_ENV=$TRY
INTERVAL_ENV=$INTERVAL
TRY_DEF=5
INTERVAL_DEF=12

# options priority
INTERVAL=$INTERVAL_DEF
TRY=$TRY_DEF
if [[ -n $INTERVAL_ENV ]]; then
    INTERVAL=$INTERVAL_ENV
fi
if [[ -n $TRY_ENV ]]; then
    TRY=$TRY_ENV
fi

# help
function instruction {
    cat << EOL
Usage: $0 [OPTIONS] <COMMAND>
Options:
  -i: try intervals in seconds (default: 5)
      environment variable name: INTERVAL
  -n: number of tries (default: 12)
      environment variable name: TRY
Options Priority:
  Highest: -explicitly use -i and -n in the command
           -read from environment variables
  Lowest : -default values for -i and -n
EOL
echo
}

if [[ $# -eq 0 ]]; then
    instruction
    exit
fi

# read options
case $1 in
    "-i")
        if [[ $2 =~ $REGEX_NUM ]]; then
            INTERVAL=$2
            OPTIONS_ARGS=$((OPTIONS_ARGS+=2))
        else
            instruction
            exit
        fi
        ;;
    "-n")
        if [[ $2 =~ $REGEX_NUM ]]; then
            TRY=$2
            OPTIONS_ARGS=$((OPTIONS_ARGS+=2))
        else
            instruction
            exit
        fi
        ;;
esac

case $3 in
    "-i")
        if [[ $4 =~ $REGEX_NUM ]]; then
            INTERVAL=$4
            OPTIONS_ARGS=$((OPTIONS_ARGS+=2))
        else
            instruction
            exit
        fi
        ;;
    "-n")
        if [[ $4 =~ $REGEX_NUM ]]; then
            TRY=$4
            OPTIONS_ARGS=$((OPTIONS_ARGS+=2))
        else
            instruction
            exit
        fi
        ;;
esac

# find the command
shift $OPTIONS_ARGS
COMMANDS=$@

if [[ -z $COMMANDS ]]; then
    instruction
fi

# execute the command
while [[ $TRY -ne 0 ]]
do
    let TRY--
    $COMMANDS 2> /dev/null
    if [[ $? -eq 0 ]]; then
        exit 0
    fi
    sleep $INTERVAL
done

echo "Operation Failed"
exit 1
