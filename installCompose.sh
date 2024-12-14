#!/usr/bin/bash

USERNAME=pi
LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/installCompose.log

function main() {
    ### Start script
    echo -e '\n-----------------------\n'
    echo -e '\n- Starting script to install docker-compose -'
    loadEnv
    pi-upgrade
    checkForDocker
    installDockerCompose
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

function checkForDocker() {
    echo -e "\n- Checking if Docker service is active -"
    if systemctl is-active --quiet docker; then
        echo -e "\n- Docker is running -"
    else
        echo -e "\n- Docker is not running. Please check the Docker installation -"
        exit 1
    fi
    
    echo -e "\n- Checking if user $USERNAME is in group docker"
    if id -nG "$USERNAME" | grep -qw docker; then
        echo -e "\n- True - \n"
    else
        echo -e "\n- False - \n"
        echo -e "$USERNAME is not in group docker. Please add user to group docker and re-run the script"
        echo -e "To add the current user to group docker, run the following command: \n\nsudo usermod -aG docker \$USER \n\n"
        exit 1
    fi
}

function installDockerCompose() {
    checkForDocker
    echo -e "\n- Install docker-compose & dependencies -"
    sudo apt install -y libffi-dev libssl-dev python3 python3-pip python3-dev

    ## Uncomment pip3 for 64bit (pi4) 
    ## Uncomment apt for 32bit (pi3/pizero)
    # sudo pip3 install docker-compose
    sudo apt install -y docker-compose
}

main
