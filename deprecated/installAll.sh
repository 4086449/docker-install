#!/usr/bin/bash

USERNAME=pi
PORTAINER_FOLDER=/home/pi/portainer
PORTAINER_IMAGE=portainer/portainer-ce:latest
PORTAINER_AGENT_IMAGE=portainer/agent:latest
PORTAINER_PASSWORD=portainer

### Stop on error
set -e

### Load environment file
source .env

setLocale() {
    # set locale
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
    sudo update-locale LANG=en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8
    sudo update-locale LANGUAGE=en_US.UTF-8
    echo "Current /default/locale: "
    cat /etc/default/locale
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANGUAGE=en_US.UTF-8
    echo "locale has been set to: "
    locale
    # echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/default/locale
    # echo "LANGUAGE=en_US.UTF-8" | sudo tee -a /etc/default/locale
#    sudo su - $USER
}

pi-upgrade() {
    sudo apt update && sudo apt full-upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y
}

updateBashrc() {
    touch /home/$USERNAME/.bashrc
    echo -e "\n\n\n\n\n##############" >> /home/$USERNAME/.bashrc
    echo "#   Custom   #" >> /home/$USERNAME/.bashrc
    echo -e "##############\n" >> /home/$USERNAME/.bashrc
    echo "alias pi-update=\"sudo apt update\"" >> /home/$USERNAME/.bashrc
    echo "alias pi-upgrade=\"sudo apt update && sudo apt full-upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y\"" >> /home/$USERNAME/.bashrc
    source /home/$USERNAME/.bashrc
}

enableVNC() {
    # Enable VNC
    echo "Enabling VNC"
    sudo raspi-config nonint do_vnc 0
}

downloadInstallScript() {
    # Download install script from github
    sudo apt install git wget curl -y
    cd /home/$USERNAME/
    git clone https://github.com/4086449/docker-install.git
}

installDocker() { 
    echo "Install dependencies"
    sudo apt install apt-transport-https ca-certificates curl gnupg-agent -y

    echo "Download script from 'https://get.docker.com' for adding the docker repo's and keys and stuff"
    curl -sSL https://get.docker.com | sh

    echo "Update again and install docker agent and dependencies from newly added docker repo"
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io
    mkdir /home/$USERNAME/.docker

    echo "Start docker and enable automatic start at boot as a service"
    sudo systemctl start docker && sudo systemctl enable docker

    echo "Add new group to user"
    sudo usermod -aG docker $USERNAME
    
    # Reload to apply group changes
    # sudo su - $USER
    # groups

    # # Reload the shell to apply the group change
    # echo "Reloading shell to apply group changes..."
    # exec sg docker newgrp `id -gn`

    # # Confirm group membership
    # echo "Verifying group membership for $USERNAME:"
    # id

}

checkForDocker() {
    echo "Checking if Docker service is active"
    if systemctl is-active --quiet docker; then
        echo "Docker is running"
    else
        echo "Docker is not running. Please check the Docker installation."
        exit 1
    fi    
    
    echo "Checking if user $USERNAME is in group docker"
    if getent group docker | grep -q "\b${USERNAME}\b"; then
        echo "- True - "
    else
        echo "- False - "
        echo "$USERNAME is not in group docker. Please add user to group docker and re-run the script"
        echo -e "To add the current user to group docker, run the following command: \n\nsudo usermod -aG docker \$USER \n\n"
        exit 1
    fi
}

installDockerCompose() {
    checkForDocker
    echo "Install docker-compose & dependencies"
    sudo apt install -y libffi-dev libssl-dev python3 python3-pip python3-dev

    ## Uncomment pip3 for 64bit (pi4) 
    ## Uncomment apt for 32bit (pi3/pizero)
    # sudo pip3 install docker-compose
    sudo apt install -y docker-compose
}

deployPortainer() {
    ##############################################################
    # Uncomment for persistent / non-persistent portainer volume #
    ##############################################################
    echo "Deploying portainer"

    ### non-persistent container
    # docker volume create portainer_data
    # docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

    ### persistent container
    mkdir -p $PORTAINER_FOLDER/data
    docker pull $PORTAINER_IMAGE
    docker run -d -p 8000:8000 -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $PORTAINER_FOLDER/data:/data $PORTAINER_IMAGE

    ### Portainer Agent
    # docker pull $PORTAINER_AGENT_IMAGE
    # docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes $PORTAINER_AGENT_IMAGE

    echo "If you came this far without issue, congrats!"

    echo "alias portainer-update=\"/home/$USERNAME/docker-install/updatePortainer.sh\"" >> /home/$USERNAME/.bashrc
    echo "alias container-update=\"/home/$USERNAME/docker-install/updateContainers.sh\"" >> /home/$USERNAME/.bashrc
    # echo "alias dc-up=\"docker-compose up -d && docker compose logs -f\"" >> /home/$USERNAME/.bashrc
    echo -e "\n" >> /home/$USERNAME/.bashrc
    source /home/$USERNAME/.bashrc
}

configPortainer() {
    # HTTP call to create admin user and set default password
    curl -L --request POST "http://localhost:9000/api/users/admin/init" --header "Content-Type: application/json" --data-raw "{\"Username\":\"admin\",\"Password\":\"$PORTAINER_PASSWORD\"}"
    # HTTP call to authenticate and record the jwt token
    JWT=$(curl -L --request POST "http://localhost:9000/api/auth" --header "Content-Type: application/json" --data-raw "{\"Username\":\"admin\",\"Password\":\"$PORTAINER_PASSWORD\"}")
    echo "JWT: $JWT"
    # HTTP call to add a new environment
    curl -L --request POST "http://localhost:9000/api/endpoints/" --header "Authorization: Bearer $JWT" Name="local" EndpointCreationType=1
}

main() {
    echo "Starting script to install docker & docker-compose"

    setLocale
    updateBashrc
    pi-upgrade
    enableVNC
    downloadInstallScript
    installDocker
    installDockerCompose
    deployPortainer
#    configPortainer

    echo "You can now start using your pi"
}

main