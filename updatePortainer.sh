#!/usr/bin/bash

### Stop on error
set -e

### Load environment file
source .env

checkForPortainer() {
    ### Check if portainer is running
    if [ "$(docker ps -a -q -f name=portainer)" ]; then
        echo "Found portainer container"
        return 0
    else
        echo "Portainer is not found!"
        exit 1
    fi
}

pullPortainerImage() {
    echo 'Pulling new image'
    pull_output=$(docker pull "$DOCKER_IMAGE" 2>&1)

    ### Check if the pull output contains "Status: Downloaded newer image"
	if grep -q "Status: Downloaded newer image" <<< "$pull_output"; then
        return true
    else
        echo '- No new image available -'
        echo 'Exiting Script'
        exit 0
    fi
}

deployNewImage() {
    echo 'Stopping container'
    docker stop portainer
    echo 'Removing container'
    docker rm portainer
    echo 'Spinning up container'
    # docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $PORTAINER_FOLDER/data:/data $DOCKER_IMAGE
}


### Start script
echo '- Starting script to update portainer -'

### uncomment to update pi
# echo '- Start update -'
# sudo apt update

### or upgrade
echo 'Start upgrade'
sudo apt update && sudo apt upgrade -y

echo 'Check if portainer is running'
checkForPortainer

echo 'Pulling new image'
pullPortainerImage

echo 'Deploying new image'
deployNewImage

echo '- Done -'
