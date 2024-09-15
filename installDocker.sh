#!/usr/bin/bash

# Stop on error
set -e

### Start script
echo '- Starting script to install docker -'

echo "Update and upgrade" 
sudo apt-get update && sudo apt-get upgrade -y

echo "Install dependencies"
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y

echo "Download script from 'https://get.docker.com' for adding the docker repo's and keys and stuff"
curl -sSL https://get.docker.com | sh

echo "Update again and install docker agent and dependencies from newly added docker repo"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

echo "Start docker and enable automatic start at boot as a service"
sudo systemctl start docker && sudo systemctl enable docker

echo "Add new group to user"
sudo usermod -aG docker $USER
sudo su - $USER

echo "Checking if current user is in group docker"
username=$USER
if getent group docker | grep -q "\b${username}\b"; then
    echo "- True - "
    echo "Finished installing docker"
else
    echo "- False - "
    echo "Something went wrong. To fix this, your device will reboot now."
    echo -e "\n\n\nIF YOU SEE THIS MESSAGE AFTER RUNNING install.sh, PLEASE RE-RUN THE SCRIPT \n\n\n"
    echo "Finishing and rebooting"

	sudo reboot 0
fi

echo '- Done -'
exit
