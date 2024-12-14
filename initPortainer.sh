#!/usr/bin/bash

USERNAME=pi
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
    echo -e '\n-----------------------\n'
    echo -e '\n- Starting script to install and portainer -'
    loadEnv
    # pi-upgrade
    checkForPortainer
    checkPortainerPassword
    configPortainer
    echo -e '\n- Done -\n\n\n'
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

function setNewPortainerPassword() {
    echo -e "\n- Please change the default password in the .env file -"
    echo -e "    1. (default) Press y or enter to wait for input and set the password."
    echo -e "    2. Press 'C' or 'c' to cancel the script and set the value in the .env file."
    echo -e "    3. Press 'P' or 'p' to proceed and change it as soon as you log in for the first time."
    
    read -s -p "\n- Choose an option: " option
    case $option in
        [Yy]*|"")
            # read -s -p "Enter new password: " new_password
            # echo
            # read -s -p "Retype new password: " retype_password
            # echo
            new_password="new_password"
            retype_password="retype_password"
            attempt=0
            while [ "$new_password" != "$retype_password" ] && [ $attempt -lt 3 ]; do
                read -s -p "Enter new password: " new_password
                echo
                read -s -p "Retype new password: " retype_password
                echo
                if [ "$new_password" != "$retype_password" ]; then
                    attempt=$((attempt+1))
                    if [ $attempt -eq 3 ]; then
                        echo -e "\n- Passwords do not match after 3 attempts, you retard! -"
                        return 1
                    else
                        echo -e "\n- Passwords do not match. $((3-attempt)) attempts left. Please try again. -"
                    fi
                fi
            done
            echo "PORTAINER_PASSWORD=$new_password" >> .env
            ;;
        c)
            echo -e "\n- Please edit the password in the .env file and re-run the script -"
            if [ ! -f .env ]; then
                touch .env
                echo -e "\n- Created .env file -"
            fi
            echo -e "\n- Adding default password to .env file -"
            echo "PORTAINER_PASSWORD=portainer" >> .env
            echo -e "- Please change the default password now! and rerun the script -"
            echo -e "- Example: -"
            echo -e "\nPORTAINER_PASSWORD=yourpassword\n"
            exit 1
            ;;
        C)
            echo -e "\n- Please set the password in the .env file and re-run the script -"
            echo -e "- Example: -"
            echo -e "\nPORTAINER_PASSWORD=yourpassword\n"
            exit 1
            ;;
        [Pp]*)
            echo -e "\n- Proceeding with default password -"
            echo -e "- Please change it AS SOON AS YOU LOG IN for the first time! -"
            echo -e "- This is important for security reasons -"
            echo -e "- Examples of security risks include: -"
            echo -e "  1. Unauthorized access to your Portainer instance."
            echo -e "  2. Potential data breaches and loss of sensitive information."
            echo -e "  3. Malicious users could deploy harmful containers or modify existing ones."
            echo -e "  4. Compromise of other services running on your Docker host."
            echo -e "- Failing to change the default password can lead to significant security vulnerabilities and potential data loss. -"
            ;;
        *)
            while [ $retries -gt 0 ]; do
                echo -e "\n- Invalid option. Please try again. -"
                retries=$((retries-1))
                read -s -p "Choose an option: " option
                case $option in
                    [Yy]*|"")
                        read -s -p "Enter new password: " new_password
                        echo
                        read -s -p "Retype new password: " retype_password
                        echo
                        retries=2
                        while [ "$new_password" != "$retype_password" ] && [ $retries -gt 0 ]; do
                            echo -e "\n- Passwords do not match. Please try again. -"
                            retries=$((retries-1))
                            read -s -p "Enter new password: " new_password
                            echo
                            read -s -p "Retype new password: " retype_password
                            echo
                        done
                        if [ "$new_password" != "$retype_password" ]; then
                            echo -e "\n- Passwords do not match after 2 attempts. Exiting -"
                            exit 1
                        fi
                        echo "PORTAINER_PASSWORD=$new_password" >> .env
                        break
                        ;;
                    c)
                        echo -e "\n- Please edit the password in the .env file and re-run the script -"
                        if [ ! -f .env ]; then
                            touch .env
                            echo -e "\n- Created .env file -"
                        fi
                        echo -e "\n- Adding default password to .env file -"
                        echo "PORTAINER_PASSWORD=portainer" >> .env
                        echo -e "- Please change the default password now! and rerun the script -"
                        echo -e "- Example: -"
                        echo -e "\nPORTAINER_PASSWORD=yourpassword\n"
                        exit 1
                        ;;
                    C)
                        echo -e "\n- Please set the password in the .env file and re-run the script -"
                        echo -e "- Example: -"
                        echo -e "\nPORTAINER_PASSWORD=yourpassword\n"
                        exit 1
                        ;;
                    [Pp]*)
                        echo -e "\n- Proceeding with default password -"
                        echo -e "- Please change it AS SOON AS YOU LOG IN for the first time! -"
                        echo -e "- This is important for security reasons -"
                        echo -e "- Examples of security risks include: -"
                        echo -e "  1. Unauthorized access to your Portainer instance."
                        echo -e "  2. Potential data breaches and loss of sensitive information."
                        echo -e "  3. Malicious users could deploy harmful containers or modify existing ones."
                        echo -e "  4. Compromise of other services running on your Docker host."
                        echo -e "- Failing to change the default password can lead to significant security vulnerabilities and potential data loss. -"
                        break
                        ;;
                    *)
                        if [ $retries -eq 0 ]; then
                            echo -e "\n- Invalid option after 2 attempts. You do not seem to be smart enough to run this script. Please refrain from running this script. Exiting -"
                            exit 1
                        fi
                        ;;
                esac
            done
            ;;
    esac
}

function checkPortainerPassword() {
    if [ "$PORTAINER_PASSWORD" == "portainer" ]; then
        retries=2
        while [ $retries -gt 0 ]; do
            subtract=setNewPortainerPassword 
            else
                echo -e "\n- Passwords do not match -"
                retries=$((retries-1))
            fi
        done
    fi
}

function configPortainer() {
    echo -e "\n- Configuring portainer -"
    # HTTP call to create admin user and set default password
    curl -L --request POST "http://localhost:9000/api/users/admin/init" --header "Content-Type: application/json" --data-raw "{\"Username\":\"$PORTAINER_ADMIN\",\"Password\":\"$PORTAINER_PASSWORD\"}"
    curl -L --request POST "http://localhost:9000/api/users/admin/init" --header "Content-Type: application/json" --data-raw "{\"Username\":\"admin\",\"Password\":\"Pr0b33rhetmaar!\"}"
    # HTTP call to authenticate and record the jwt token
    JWT=$(curl -L --request POST "http://localhost:9000/api/auth" --header "Content-Type: application/json" --data-raw "{\"Username\":\"admin\",\"Password\":\"$PORTAINER_PASSWORD\"}")
    echo -e "\n- JWT: -\n$JWT"
    # HTTP call to add a new environment
    curl -L --request POST "http://localhost:9000/api/endpoints/" --header "Authorization: Bearer $JWT" Name="local" EndpointCreationType=1
}

main

