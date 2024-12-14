#!/usr/bin/bash

USERNAME=pi
LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/updatePortainer.log
PORTAINER_FOLDER=/home/$USERNAME/portainer
PORTAINER_IMAGE=portainer/portainer-ce:latest
PORTAINER_AGENT_IMAGE=portainer/agent:latest
PERSISTANT=true

function main() {
    ### Start script
    echo -e "\n-----------------------\n"
    echo -e "\n- Starting script to update portainer -"
    loadEnv
    pi-upgrade
    updateImages
    echo -e "\n- Done -\n"
    exit 0
}

function loadEnv() {
    echo -e "\n- Loading environment -"
    # Stop on error
    set -e
    ### Logfile
    mkdir -p $LOGFOLDER
    exec > >(tee -a $LOGFILE) 2>&1

    ### Load environment file
    if [ ! -f .env ]; then
        touch .env
        echo -e "\n- Created .env file -"
    fi
    source .env
}

function pi-upgrade() {
    echo -e "\n- pi-upgrade -"
    sudo apt update && sudo apt full-upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y
}

function checkForPortainer() {
    ### Check if portainer is running
    if [ "$(docker ps -a -q -f name=portainer)" ]; then
        echo -e "\n- Found portainer -"
        return 0
    else
        echo -e "\n- Portainer is not found! -"
        return 1
    fi
}

function checkForPortainerAgent() {
    ### Check if portainer_agent is running
    if [ "$(docker ps -a -q -f name=portainer_agent)" ]; then
        echo -e "\n- Found portainer_agent -"
        return 0
    else
        echo -e "\n- Portainer Agent is not found! -"
        return 1
    fi
}

function validateSHA() {
    if [ -z "$1" ]; then
        return 1
    fi
    if [[ "$1" =~ ^sha256:[a-f0-9]{64}$ ]]; then
        return 0
    else
        return 1
    fi
}

function pullPortainerImage() {
    echo -e "\n- Checking for new Portainer image -"
    current_digest=$(docker inspect --format='json' "$PORTAINER_IMAGE" | jq -r '.[0].Image' | cut -d':' -f2)
    if ! validateSHA "$current_digest"; then
        echo -e "\n- Invalid SHA for current image $PORTAINER_AGENT_IMAGE -"
        return 1
    fi
    echo -e "\n- Current version: $current_digest -"
    latest_digest=$(curl -s https://hub.docker.com/v2/repositories/portainer/portainer-ce/tags/latest | jq -r '.images[] | select(.architecture == "arm64") | .digest')
    if ! validateSHA "$latest_digest"; then
        echo -e "\n- Invalid SHA for latest image $PORTAINER_AGENT_IMAGE -"
        return 1
    fi
    echo -e "\n- Latest version: $latest_digest -"

    if [ "$current_digest" != "$latest_digest" ]; then
        echo -e "\n- New image available, pulling new Portainer image -"
        docker pull "$PORTAINER_IMAGE"
        return 0
    else
        echo -e "\n- No new image available for $PORTAINER_IMAGE -"
        return 1
    fi
}

function pullPortainerAgentImage() {
    echo -e "\n- Checking for new Portainer image -"
    current_digest=$(docker inspect --format='json' "$PORTAINER_AGENT_IMAGE" | jq -r '.[0].Image')
    if ! validateSHA "$current_digest"; then
        echo -e "\n- Invalid SHA for current image $PORTAINER_AGENT_IMAGE -"
        return 1
    fi
    echo -e "\n- Current version: $current_digest -"
    latest_digest=$(curl -s https://hub.docker.com/v2/repositories/portainer/agent/tags/latest | jq -r '.images[] | select(.architecture == "arm64") | .digest')
    if ! validateSHA "$latest_digest"; then
        echo -e "\n- Invalid SHA for latest image $PORTAINER_AGENT_IMAGE -"
        return 1
    fi
    echo -e "\n- Latest version: $latest_digest -"

    if [ "$current_digest" != "$latest_digest" ]; then
        echo -e "\n- New image available, pulling new Portainer image -"
        docker pull "$PORTAINER_AGENT_IMAGE"
        return 0
    else
        echo -e "\n- No new image available for $PORTAINER_AGENT_IMAGE -"
        return 1
    fi
}

function deployNewPortainerImage() {
    echo -e "\n- Stopping container -"
    docker stop portainer
    echo -e "\n- Removing container -"
    docker rm portainer
    echo -e "\n- Spinning up container -"
    if [[ "$PERSISTANT" == true ]]; then
        docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $PORTAINER_FOLDER/data:/data $PORTAINER_IMAGE
    else
        docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data $PORTAINER_IMAGE
    fi
}

function deployNewPortainerAgentImage() {
    echo -e "\n- Stopping container -"
    docker stop portainer
    echo -e "\n- Removing container -"
    docker rm portainer
    echo -e "\n- Spinning up container -"
    docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes $PORTAINER_AGENT_IMAGE
}

function updateImages() {
    # Make sure portainer is running. No container, no update, no agent update
    if checkForPortainer; then
        # New image available? Pull and deploy
        if pullPortainerImage; then
            deployNewPortainerImage
        fi
        # Agent running && New image available? Pull and deploy
        if checkForPortainerAgent && pullPortainerAgentImage; then
            deployNewPortainerAgentImage
        fi
    else
        echo -e "\n- Portainer is not running, exiting -"
        exit 1        
    fi
}

main
