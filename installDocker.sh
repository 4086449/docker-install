#!/usr/bin/env bash

USERNAME="${USERNAME:-$USER}"
LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/installDocker.log

function main() {
    ### Start script
    echo -e '\n=========================================='
    echo -e '  INSTALL DOCKER'
    echo -e '  Steps: upgrade -> deps -> get.docker.com -> enable service -> add user to group'
    echo -e '==========================================\n'
    loadEnv

    echo -e "\n[Docker 1/5] Upgrading system packages (this may take several minutes)..."
    pi-upgrade
    echo -e "[Docker 1/5] Done.\n"

    echo -e "[Docker 2/5] Installing dependencies..."
    installDeps
    echo -e "[Docker 2/5] Done.\n"

    echo -e "[Docker 3/5] Downloading and running get.docker.com install script (this may take a few minutes)..."
    installDockerEngine
    echo -e "[Docker 3/5] Done.\n"

    echo -e "[Docker 4/5] Enabling Docker service at boot..."
    enableDocker
    echo -e "[Docker 4/5] Done.\n"

    echo -e "[Docker 5/5] Adding user '$USERNAME' to docker group..."
    addUserToGroup
    echo -e "[Docker 5/5] Done.\n"

    echo -e '\n  Docker installation complete.\n'
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

function installDeps() {
    sudo apt install ca-certificates curl gnupg -y
}

function installDockerEngine() {
    echo -e "  Downloading get-docker.sh..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    echo -e "  Running get-docker.sh (installs docker-ce, docker-ce-cli, containerd.io, docker-compose-plugin)..."
    sudo sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    mkdir -p /home/$USERNAME/.docker
}

function enableDocker() {
    sudo systemctl start docker && sudo systemctl enable docker
    echo -e "  Docker service started and enabled."
}

function addUserToGroup() {
    sudo usermod -aG docker $USERNAME
    echo -e "  User '$USERNAME' added to group 'docker'."
}

main
