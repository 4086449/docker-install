#!/bin/bash

LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/install.log

### Stop on error
set -e
### Logfile
mkdir -p $LOGFOLDER
exec > >(tee -a $LOGFILE) 2>&1

### Setup NOPASSWD for current user so the rest runs unattended
if ! sudo -n true 2>/dev/null; then
    echo -e "\n- Setting up passwordless sudo (you may be prompted once) -"
    sudo -v
fi
if [ ! -f /etc/sudoers.d/$USER ]; then
    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER > /dev/null
    sudo chmod 0440 /etc/sudoers.d/$USER
    echo -e "- NOPASSWD configured for $USER -"
fi

echo -e "\n=========================================="
echo -e "  DOCKER INSTALL - FULL SETUP"
echo -e "\n  Steps: [1/4] Pi Config -> [2/4] Docker -> [3/4] Compose -> [4/4] Portainer"
echo -e "==========================================\n"

echo -e "\n[1/4] ======== CONFIGURING RASPBERRY PI ========\n"
./installPi.sh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
source /home/$USER/.bashrc

echo -e "\n[2/4] ======== INSTALLING DOCKER ========\n"
./installDocker.sh

echo -e "\n[3/4] ======== INSTALLING DOCKER COMPOSE ========\n"
./installCompose.sh

echo -e "\n[4/4] ======== INSTALLING PORTAINER ========\n"
newgrp docker << END
(./installPortainer.sh)
END

echo -e "\n=========================================="
echo -e "  ALL DONE! Full installation complete."
echo -e "==========================================\n"

exit 0
