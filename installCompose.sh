#!/usr/bin/env bash

USERNAME="${USERNAME:-$USER}"
LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/installCompose.log

function main() {
    ### Start script
    echo -e '\n-----------------------\n'
    echo -e '\n- Starting script to install docker compose -'
    loadEnv
    installCompose
    verifyCompose
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

function installCompose() {
    echo -e "\n- Installing docker-compose-plugin -"
    sudo apt install -y docker-compose-plugin
}

function verifyCompose() {
    echo -e "\n- Verifying docker compose installation -"
    docker compose version
}

main
