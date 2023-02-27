# About
It is a group of **useful shell scripts** for DevOps engineers, System administrators and developers.

## How
Each script has a different purpose and scripts are not related to each other.
Find a useful script from this readme file then use it.

## Contribution
Feel free and don't hesitate contributing to this repository.

# List
+ try_interval.sh
+ bulk_commands.sh

### try_interval.sh
Try to execute a command until a successful result or reach a limitation in number of *tries* based on an *interval time* between each try.

### bulk_commands.sh
Execute same command for all lines of a file as input.
For example, we have a IPs.txt file and each line of the file has an IP address. We want to allow all IPs using iptables command. So we run:
#sudo ./bulk_commands.sh -f cdnips.txt iptables -A INPUT -s PARM -j ACCEPT
PARM is replaced by each line of the file (which contains an IP address in this example)