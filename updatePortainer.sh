#!/usr/bin/bash

PORTAINER_FOLDER=/home/pi/portainer
PORTAINER_IMAGE=portainer/portainer-ce:latest
PORTAINER_AGENT_IMAGE=portainer/agent:latest

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

checkForPortainerAgent() {
    ### Check if portainer_agent is running
    if [ "$(docker ps -a -q -f name=portainer_agent)" ]; then
        echo "Found portainer_agent container"
        return 0
    else
        echo "Portainer Agent is not found!"
        exit 1
    fi
}

pullPortainerImage() {
    echo 'Pulling new Portainer image'
    pull_output=$(docker pull "$PORTAINER_IMAGE" 2>&1)

    ### Check if the pull output contains "Status: Downloaded newer image"
	if grep -q "Status: Downloaded newer image for $PORTAINER_IMAGE" <<< "$pull_output"; then
        return true
    else
        echo "- No new image available for $PORTAINER_IMAGE -"
        return false
    fi
}

pullPortainerAgentImage() {
    echo 'Pulling new Portainer Agent image'
    pull_output=$(docker pull "$PORTAINER_AGENT_IMAGE" 2>&1)

    ### Check if the pull output contains "Status: Downloaded newer image"
	if grep -q "Status: Downloaded newer image for $PORTAINER_AGENT_IMAGE" <<< "$pull_output"; then
        return true
    else
        echo "- No new image available for $PORTAINER_AGENT_IMAGE -"
        return false
    fi
}

deployNewPortainerImage() {
    echo 'Stopping container'
    docker stop portainer
    echo 'Removing container'
    docker rm portainer
    echo 'Spinning up container'
    # docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $PORTAINER_FOLDER/data:/data $PORTAINER_IMAGE
}

deployNewPortainerAgentImage() {
    echo 'Stopping container'
    docker stop portainer
    echo 'Removing container'
    docker rm portainer
    echo 'Spinning up container'
    docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes $PORTAINER_AGENT_IMAGE
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
deployNewPortainerImage

echo 'Check if portainer_agent is running'
checkForPortainer

echo 'Pulling new image'
pullPortainerAgentImage

echo 'Deploying new image'
deployNewPortainerAgentImage

echo '- Done -'
