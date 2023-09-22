# About
It is a group of **useful shell scripts** for DevOps engineers, System administrators and developers.

# How
Each script has a different purpose and scripts are not related to each other.
Find a useful script from this readme file then use it.

# List
+ try_interval.sh
+ bulk_commands.sh
+ backup_ftp.sh

### try_interval.sh
Try to execute a command until a successful result or reach a limitation in number of *tries* based on an *interval time* between each try.

Example:

#./try_interval.sh -i 6 -n 3 mycommand

### bulk_commands.sh
Execute same command for all lines of a file as input.

For example, we have a IPs.txt file and each line of the file has an IP address. We want to allow all IPs using iptables command. So we run:

#sudo ./bulk_commands.sh -f cdnips.txt iptables -A INPUT -s PARM -j ACCEPT

PARM is replaced by each line of the file (which contains an IP address in this example)

### backup_ftp.sh
Create a tar.gz file from a given directory, then upload it to a ftp backup storage.
If your backup storage supports secure protocols/methods (e.g: rsync/scp/sftp/...), you should use another method instead of FTP.
You can use FTP_STORAGE_PASS environment variable instead of -p option.

Example usage:

#backup_ftp.sh -d /home/myuser/myfiles/ -o /tmp/backups/bkp-$(date '+%Y-%m-%d-%H-%M-%S').tar.gz -u b110973 -f b110973.myftpserver.org -p f67Eex1JsfR8bB -r

# Contribution
Feel free and don't hesitate contributing to this repository.
