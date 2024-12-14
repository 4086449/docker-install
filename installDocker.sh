#!/usr/bin/bash

USERNAME=pi
LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/installDocker.log

function main() {
    ### Start script
    echo -e '\n-----------------------\n'
    echo -e '\n- Starting script to install docker -'
    loadEnv
    pi-upgrade
    installDocker
    echo -e '\n- Done -\n'
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

function installDocker() { 
    echo -e "\n- Install dependencies -"
    sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y

    echo -e "\n- Download script from 'https://get.docker.com' for adding the docker repo's and keys and stuff -"
    curl -sSL https://get.docker.com | sh

    echo -e "\n- Update again and install docker agent and dependencies from newly added docker repo -"
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io
    mkdir /home/$USERNAME/.docker

    echo -e "\n- Start docker and enable automatic start at boot as a service -"
    sudo systemctl start docker && sudo systemctl enable docker

    echo -e "\n- Add new group to user -"
    sudo usermod -aG docker $USERNAME
}

main
