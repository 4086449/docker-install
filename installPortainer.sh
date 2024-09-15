#!/usr/bin/bash

### Stop on error
set -e

### Load environment file
source .env

### Start script
echo "- Starting script to install docker-compose and portainer -"

echo "Checking if user pi is in group docker"
username=$USER
if getent group docker | grep -q "\b${username}\b"; then
    echo "- True - "
else
    echo "- False - "
    echo "User is not in group docker. Please add user to group docker and re-run the script"
    echo -e "To add the current user to group docker, run the following command: \n\nsudo usermod -aG docker \$USER \n\n"
	exit 1
fi

echo "Install docker-compose & dependencies"

### Install dependencies
sudo apt install -y libffi-dev libssl-dev python3 python3-pip python3-dev

### Install docker-compose
sudo apt install -y docker-compose

### If apt install docker-compose fails, use pip to install docker-compose
# sudo python3 -m pip install docker-compose

echo "Check if docker is up and running by returning the version"
docker version
docker ps

##############################################################
# Uncomment for persistent / non-persistent portainer volume #
##############################################################
echo "Deploying portainer"
docker pull $DOCKER_IMAGE

### non-persistent container
# docker volume create portainer_data
# docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

### persistent container
mkdir -p $PORTAINER_FOLDER/data
docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $PORTAINER_FOLDER/data:/data $DOCKER_IMAGE

echo "If you came this far without issue, congrats!"
echo "You can now start deploying containers"
echo '- Done -'
