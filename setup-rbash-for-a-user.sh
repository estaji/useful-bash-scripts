#!/bin/bash

############## Description ##############################
# This script setups RBASH for a user that is already created.
# Do not use it for root.
# Copy allowed binary/commands (e.g rsync) to /home/$USERNAME/bin directory.
########################################################

# Variables
STORAGE_DIR_NAME_AS_HOME="server1"
USERNAME="server1"
ALLOWED_BINARY="/usr/bin/rsync"

# Main
logger -p local6.info -t "setup-rbash" "###### Configuring rbash for $USERNAME started ... ######"

# Create a .bash_profile for the user
echo "cd /storage/$STORAGE_DIR_NAME_AS_HOME/" > /home/$USERNAME/.bash_profile
chown $USERNAME:$USERNAME /home/$USERNAME/.bash_profile

# Set PATH to a limited bin directory
mkdir -p /home/$USERNAME/bin
cp $ALLOWED_BINARY /home/$USERNAME/bin
chown -R $USERNAME:$USERNAME /home/$USERNAME/bin
echo "export PATH=\$HOME/bin" >> /home/$USERNAME/.bash_profile

# Use rbash as shell
chsh -s /bin/rbash $USERNAME

# To secure replacing the .bash_profile by user rsync
chattr +i /home/$USERNAME/.bash_profile
chattr +i /home/$USERNAME/.bashrc

logger -p local6.info -t "setup-rbash" "###### Configuring rbash for $USERNAME finished ... ######"
