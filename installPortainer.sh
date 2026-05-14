#!/usr/bin/env bash

USERNAME="${USERNAME:-$USER}"
LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/installPortainer.log
PORTAINER_FOLDER=/home/$USERNAME/portainer
PORTAINER_IMAGE=portainer/portainer-ce:latest
PORTAINER_AGENT_IMAGE=portainer/agent:latest
# CHANGE THIS TO YOUR OWN PASSWORD!!!
## Use .env file
PORTAINER_PASSWORD=portainer
PORTAINER_ADMIN=admin

function main() {
    ### Start script
    echo -e '\n=========================================='
    echo -e '  INSTALL PORTAINER'
    echo -e '  Steps: upgrade -> check docker -> pull image -> deploy container -> aliases'
    echo -e '==========================================\n'
    loadEnv

    echo -e "\n[Portainer 1/4] Upgrading system packages (this may take several minutes)..."
    pi-upgrade
    echo -e "[Portainer 1/4] Done.\n"

    echo -e "[Portainer 2/4] Checking Docker prerequisites..."
    checkForDocker
    echo -e "[Portainer 2/4] Done.\n"

    echo -e "[Portainer 3/4] Pulling and deploying Portainer container..."
    deployPortainer
    echo -e "[Portainer 3/4] Done.\n"

    echo -e "[Portainer 4/4] Setting up aliases..."
    setupAliases
    echo -e "[Portainer 4/4] Done.\n"

    echo -e '\n  Portainer installation complete.\n'
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
    echo -e "  Running: apt update..."
    sudo apt update
    echo -e "  Running: apt full-upgrade (this is the slow part)..."
    sudo apt full-upgrade -y
    echo -e "  Running: apt dist-upgrade..."
    sudo apt dist-upgrade -y
    echo -e "  Running: apt autoremove..."
    sudo apt autoremove -y
}

function checkForDocker() {
    echo -e "\n- Checking if Docker service is active -"
    if systemctl is-active --quiet docker; then
        echo -e "\n- Docker is running -"
    else
        echo -e "\n- Docker is not running. Please check the Docker installation -"
        exit 1
    fi    
    
    echo -e "\n- Checking if user $USERNAME is in group docker"
    if getent group docker | grep -q "\b${USERNAME}\b"; then
        echo -e "\n- True -\n"
    else
        echo -e "\n- False -\n"
        echo -e "$USERNAME is not in group docker. Please add user to group docker and re-run the script"
        echo -e "To add the current user to group docker, run the following command: \n\nsudo usermod -aG docker \$USER \n\n"
        exit 1
    fi
}

function deployPortainer() {
    ##############################################################
    # Uncomment for persistent / non-persistent portainer volume #
    ##############################################################
    echo -e "\n- Deploying portainer -"

    ### non-persistent container
    # docker volume create portainer_data
    # docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

    ### persistent container
    mkdir -p $PORTAINER_FOLDER/data
    echo -e "  Pulling image: $PORTAINER_IMAGE"
    docker pull $PORTAINER_IMAGE
    echo -e "  Starting container on ports 8000, 9000, 9443..."
    docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $PORTAINER_FOLDER/data:/data $PORTAINER_IMAGE

    ### Portainer Agent
    # docker pull $PORTAINER_AGENT_IMAGE
    # docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes $PORTAINER_AGENT_IMAGE

    echo -e "  Portainer container is running."
}

function setupAliases() {
    if ! grep -q "# docker-install managed aliases" /home/$USERNAME/.bashrc; then
        echo -e "  Adding aliases to .bashrc..."
        echo -e "# docker-install managed aliases" >> /home/$USERNAME/.bashrc
        echo -e "alias portainer-update=\"/home/$USERNAME/docker-install/updatePortainer.sh\"" >> /home/$USERNAME/.bashrc
        echo -e "alias container-update=\"/home/$USERNAME/docker-install/updateContainers.sh\"" >> /home/$USERNAME/.bashrc
        echo -e "\n" >> /home/$USERNAME/.bashrc
    else
        echo -e "  Aliases already present, skipping."
    fi
    source /home/$USERNAME/.bashrc
}

main
