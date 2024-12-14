#!/usr/bin/bash

USERNAME=pi
LOGFOLDER=./logs
LOGFILE=./$LOGFOLDER/installPi.log

function main() {
    ### Start script
    echo -e '\n-----------------------\n'
    echo -e '\n- Starting script to config pi -'
    echo -e "\n- Current user: $USER -"
    loadEnv
    setLocale
    updateBashrc
    pi-upgrade
    enableVNC
    downloadInstallScript
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

function setLocale() {
    # set locale
    echo -e "\n- Setting locale -"
    # Check if LC_ALL is set to en_US.UTF-8
    if [ "$(locale | grep 'LC_ALL=en_US.UTF-8')" ]; then
        echo "LC_ALL is correctly set to en_US.UTF-8"
        return 0
    # else
    #     echo "Error: LC_ALL is not set to en_US.UTF-8"
    #     return 1
    fi    
    # check the uncommented locales
    grep "^[^#;]" /etc/locale.gen

    # uncomment the wanted locale
    # @note this uncomment en_US.UTF-8
    sudo sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    sudo localectl list-locales
    # generate locales
    # The uncommented locales in /etc/locale.gen will be generated
    sudo locale-gen
    # sudo locale-gen en_US.UTF-8
    sudo localectl set-locale LANG=en_US.UTF-8
    # sudo update-locale LANG=en_US.UTF-8
    # sudo update-locale LC_ALL=en_US.UTF-8
    # sudo update-locale LANGUAGE=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANGUAGE=en_US.UTF-8
    # echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
    # echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale
    echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/default/locale
    echo "LANGUAGE=en_US.UTF-8" | sudo tee -a /etc/default/locale
    echo -e "\n- Current /default/locale: -"
    cat /etc/default/locale
    echo -e "\n- locale has been set to: -"
    locale
}

function updateBashrc() {
    echo -e "\n- Setting aliases -"
    touch /home/$USERNAME/.bashrc
    echo -e "\n\n\n\n\n##############" >> /home/$USERNAME/.bashrc
    echo -e "#   Custom   #" >> /home/$USERNAME/.bashrc
    echo -e "##############\n" >> /home/$USERNAME/.bashrc
    echo "alias pi-update=\"sudo apt update\"" >> /home/$USERNAME/.bashrc
    echo "alias pi-upgrade=\"sudo apt update && sudo apt full-upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y\"" >> /home/$USERNAME/.bashrc
    source /home/$USERNAME/.bashrc
}

function enableVNC() {
    echo -e "\n- Enabling VNC -"
    # Enable VNC
    sudo raspi-config nonint do_vnc 0
}

function downloadInstallScript() {
    # Download install script from github
    sudo apt install git wget curl -y
    cd /home/$USERNAME/
    git clone https://github.com/4086449/docker-install.git
}

main