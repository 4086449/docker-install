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
        return 0
    else
        echo '- No new image available -'
        echo 'Exiting Script'
        exit 0
    fi
}

deployNewImage() {
    echo -e '  Stopping container...'
    docker stop portainer
    echo -e '  Removing old container...'
    docker rm portainer
    echo -e '  Starting new container with updated image...'
    docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $PORTAINER_FOLDER/data:/data $DOCKER_IMAGE
    echo -e '  New container is running.'
}


### Start script
echo -e '\n=========================================='
echo -e '  UPDATE PORTAINER'
echo -e '  Steps: upgrade -> check -> pull -> redeploy'
echo -e '==========================================\n'

echo -e "[1/4] Upgrading system packages..."
sudo apt update && sudo apt upgrade -y
echo -e "[1/4] Done.\n"

echo -e "[2/4] Checking if Portainer is running..."
checkForPortainer
echo -e "[2/4] Done.\n"

echo -e "[3/4] Pulling new image: $DOCKER_IMAGE ..."
pullPortainerImage
echo -e "[3/4] Done.\n"

echo -e "[4/4] Deploying new image..."
deployNewImage
echo -e "[4/4] Done.\n"

echo -e '\n  Portainer update complete.\n'
