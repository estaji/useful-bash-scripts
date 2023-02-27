#!/bin/bash

# help
function instruction {
    cat << EOL
Description:
  Execute a given command which is included PARM,
  and replace PARM with each line of a given file.
Usage: $0 [OPTIONS] <COMMAND>
Options:
  -f: file path
Example:
  sudo $0 -f cdnips.txt iptables -A INPUT -s PARM -j ACCEPT
  cdnips.txt contains a lot of IPs (each line one IP)
  This command will execute the iptables command for all IPs in the file
EOL
echo
}

# arguments section
if [[ $# -eq 0 ]]; then
    instruction
    exit
fi

case $1 in
    "-f")
        if [ -f "$2" ]; then
            FILE=$2
            shift 2
        else
            instruction
            exit
        fi
        ;;
    *)
      instruction
      exit
        ;;
esac

COMMAND=$@

# main section
if [[ "$COMMAND" == *"PARM"* ]]; then
  while IFS= read LINE
  do
    EXECUTE=$(echo "$COMMAND" | awk -v r=$LINE '{gsub(/PARM/,r)}1')
    $EXECUTE
  done <"$FILE"
else
  echo "Your COMMAND should contains at least one PARM as replacement."
  echo
  instruction
  exit
fi
