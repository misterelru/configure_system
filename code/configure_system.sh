#!/bin/bash

set -euo pipefail

# Check launch options
if [ $# -eq 0 ];
then
    echo "Missing options!"
    echo "(run $0 -h for help)"
    exit 0;
fi

# Set variables
CURRENT_USER=$(whoami)
HOMEDIR=$( getent passwd "${CURRENT_USER}" | cut -d: -f6 )
PATH_TO_THIS_SCRIPT=$(dirname "$0")
PATH_TO_TEMPLATES="${PATH_TO_THIS_SCRIPT}"/../templates
TMP_DIR="${PATH_TO_THIS_SCRIPT}"/../tmp
RELEASE="$(lsb_release -cs)"

# Checking OS release
if [ "$RELEASE" != "focal" ];
then
    echo "Unsupported OS release"
    exit 0;
fi

# Question for the user
QuestionForTheUser() {

    echo -n "$1"
    read -r user_response
    case ${user_response} in
        y|Y|yes|Yes )
            ${2-};;
        n|N|no|No )
            echo "Passed!";;
        * )
            echo "Not y/n"
            exit 0;;
    esac

}

# Disable swap
DisableSwap() {

CheckAndDisable() {

    if sudo swapon -s;
    then
        sudo swapoff -a
    fi
    sudo sed -i "/ swap / s/^/#/" /etc/fstab

}

    QuestionForTheUser \
    "Do you want to disable swap? (y/n) " \
    CheckAndDisable \
    || { echo 'error in function, line 58' | exit 0; }

}

# Copy ssh keys
CopySSHkeys() {

    unzip "${PATH_TO_THIS_SCRIPT}"/../files/ssh-folder.zip -d "${TMP_DIR}"
    rm -R "${HOMEDIR}"/.ssh > /dev/null
    cp -R "${TMP_DIR}"/ssh "${HOMEDIR}"/.ssh
    chmod go-rwx "${HOMEDIR}"/.ssh/*

}

# Install network tools
InstallNetworkTools() {

    # Install Wireshark
    sudo apt-get install -y wireshark
    sudo usrermod -aG wireshark "${CURRENT_USER}"

    # Install Winbox
    sudo apt-get -y install wine-stable
    if ! test -f /bin/winbox64;
    then
        wget https://mt.lv/winbox64 -P "${TMP_DIR}" || \
        { echo " !!! failed to download winbox !!! " | exit 2; }
        sudo mv "${TMP_DIR}"/winbox64 /bin;
    fi

}

# Configure Git
ConfigureGit() {

    git config --global user.name "$1"
    git config --global user.email "$2"
    git config --global core.autocrlf input
    git config --global core.safecrlf warn
    git config --global core.quotepath off

}

# Add the aliases in the bashrc file
BashAliases() {

    cp "${PATH_TO_TEMPLATES}"/"$1" "${HOMEDIR}"/.bash_aliases
    sed -i -e "s/USERNAME/${CURRENT_USER}/g" \
    "${HOMEDIR}"/.bash_aliases

}

# Add autorun ssh-agent in ~/.bashrc
SSHAgent() {

    echo "Check autorun ssh-agent in '${HOMEDIR}'/.bashrc"
    if grep -R SSH_AUTH_SOCK "${HOMEDIR}"/.bashrc;
    then
        echo "Passed!"
    else
        echo "Add settings in '${HOMEDIR}'/.bashrc"
        sed -i -e \
'$a\
# Autorun ssh-agent for teleport\
if [ -z "$SSH_AUTH_SOCK" ] ; then\
    eval `ssh-agent -s`\
    ssh-add\
fi\ ' "${HOMEDIR}"/.bashrc;
    fi

}

# Sync the database for keepassxc from google drive
SyncDatabaseFromGoogleDrive() {

    # Mount google drive
    if ! dpkg -l | grep -i google-drive > /dev/null;
    then
        sudo add-apt-repository ppa:alessandro-strada/ppa -y
        sudo apt-get update && sudo apt-get install google-drive-ocamlfuse -y
        nohup google-drive-ocamlfuse & sleep 300
        mkdir "${HOMEDIR}"/my-google-drive
        google-drive-ocamlfuse "${HOMEDIR}"/my-google-drive;
    fi

    # Install KeepassXC
    if ! dpkg -l | grep -i keepassxc > /dev/null;
    then
        sudo add-apt-repository ppa:phoerious/keepassxc -y
        sudo apt-get update && sudo apt-get install keepassxc -y;
    fi

    # Copy the keepass database and sync it
    PATH_TO_DB=$(find "${HOMEDIR}"/my-google-drive -iname 'database*' \
    | grep -iv trash)
    mkdir "${HOMEDIR}"/keepass-db

    cp "${PATH_TO_DB}" "${HOMEDIR}"/keepass-db/
    cp "${PATH_TO_THIS_SCRIPT}"/sync_file.py "${HOMEDIR}"/keepass-db/

    chmod 744 "${HOMEDIR}"/keepass-db/sync_file.py

    cp "${PATH_TO_TEMPLATES}"/google-drive-ocamlfuse.service "${TMP_DIR}"/
    cp "${PATH_TO_TEMPLATES}"/sync_keepass_database.service "${TMP_DIR}"/

    sed -i -e "s!USERNAME!${CURRENT_USER}!
    s!DRIVE_DIR!${HOMEDIR}/my-google-drive!g" \
    "${TMP_DIR}"/google-drive-ocamlfuse.service

    sed -i -e "s!USERNAME!${CURRENT_USER}!
    s!DB_DIR!${HOMEDIR}/keepass-db!
    s!DB_FILE!${HOMEDIR}/keepass-db/Database.kdbx!g" \
    "${TMP_DIR}"/sync_keepass_database.service

    sudo cp "${TMP_DIR}"/google-drive-ocamlfuse.service \
    /etc/systemd/system/google-drive-ocamlfuse.service
    sudo cp "${TMP_DIR}"/sync_keepass_database.service \
    /etc/systemd/system/sync_keepass_database.service

    sudo chmod 644 /etc/systemd/system/google-drive-ocamlfuse.service
    sudo chmod 644 /etc/systemd/system/sync_keepass_database.service

    sudo systemctl daemon-reload
    sudo systemctl enable --now google-drive-ocamlfuse.service \
    sync_keepass_database.service

}

# Install without my system config
StandartInstall() {

    # Set timeout to run sudo command
    sudo sed -i 's/env_reset/&, timestamp_timeout=60/' /etc/sudoers

    # Update all packages
    sudo apt-get update
    sudo apt-get full-upgrade -y
    sudo apt-get autoclean
    sudo apt-get autoremove -y

    # Install apps
    ./"${PATH_TO_THIS_SCRIPT}"/prepare_apps.sh

    # Change background color
    sudo apt-get install libglib2.0-dev-bin -y
    chmod a+x "${PATH_TO_THIS_SCRIPT}"/change-gdm-background
    sudo "${PATH_TO_THIS_SCRIPT}"/change-gdm-background \#000000

    # Question to the user about ssh-agent
    QuestionForTheUser \
    "Do you want to enable auto running ssh-agent? (y/n) " \
    SSHAgent \
    || { echo 'error in function, line 210' | exit 0; }

}

# Install my system config
FullInstallWithConfigs() {

    # Question to the user about vanilla gnome
    QuestionForTheUser \
    "Do you want to install vanilla gnome? (y/n) " \
    "sudo apt-get install gnome-session -y"\
    || { echo 'error in function, line 221' | exit 0; }

    # Question to the user about network tools
    QuestionForTheUser \
    "Do you want to install wireshark and winbox? (y/n) " \
    InstallNetworkTools \
    || { echo 'error in function, line 227' | exit 0; }

    # Question to the user about git config
    echo -en "Configure git for A.Osipov? \n
    1 To cofiguring git for A.Osipov \n
    2 To entering the manual username \n
    3 To do nothing \n
    Enter option: "
        read -r user_response
        case ${user_response} in
            1 )
                ConfigureGit alekseyosipov aleksey.osipov@piano.io;;
            2 )
                echo "Enter username"
                read -r USERNAME
                echo "Enter email"
                read -r EMAIL
                ConfigureGit "${USERNAME}" "${EMAIL}";;
            3 )
                echo "Passed!";;
            * )
                echo "Not 1/2/3"
                exit 0;;
        esac

    # Question to the user about SSH keys
    QuestionForTheUser \
    "Do you want to copy SSH keys? (y/n) " \
    CopySSHkeys \
    || { echo 'error in function, line 256' | exit 0; }

    # Question to the user about keepassdb
    QuestionForTheUser \
    "Mount GoogleDrive and copy keepass db? (y/n) " \
    SyncDatabaseFromGoogleDrive \
    || { echo 'error in function, line 262' | exit 0; }

}

# Make tmp dir
if ! test -d "${PATH_TO_THIS_SCRIPT}"/../tmp;
then
    mkdir "${PATH_TO_THIS_SCRIPT}"/../tmp;
fi

# Check installation options and run the desired script
while getopts "hfs" OPTION; do
    case ${OPTION} in
        f)
            DisableSwap
            StandartInstall
            FullInstallWithConfigs
            BashAliases bash_aliases;;
        s)
            DisableSwap
            StandartInstall
            BashAliases bash_aliases_simple;;
        h)
            echo "Usage:"
            echo "$0 -h for help"
            echo "$0 -f for full install"
            echo "$0 -s for simple install"
            exit 0;;
        *)
            echo "usage: $0 [-f] [-s] [-h]" >&2
            exit 1;;
    esac
done

# Clear tmp directory
rm -rf "${TMP_DIR:?}/"*

# Reboot system
sudo shutdown -r +2
