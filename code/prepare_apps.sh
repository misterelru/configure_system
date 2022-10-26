#!/bin/bash

set -euo pipefail

CURRENT_USER=$(whoami)
PATH_TO_THIS_SCRIPT=$(dirname "$0")
TMP_DIR="${PATH_TO_THIS_SCRIPT}"/../tmp

# Remove default games
sudo apt-get remove -y gnome-mahjongg gnome-sudoku gnome-mines aisleriot

# Add archirecture i386 and install multiverse
sudo dpkg --add-architecture i386
sudo add-apt-repository multiverse -y
sudo apt-get update
sudo apt-get full-upgrade -y

# Install gnome extensions
xargs -a "${PATH_TO_THIS_SCRIPT}"/../files/gnome_extensions \
sudo apt-get install -y

# Install codecs
sudo apt-get install -y ubuntu-restricted-extras libavcodec-extra libdvd-pkg
sudo dpkg-reconfigure libdvd-pkg

# Install language packages
xargs -a "${PATH_TO_THIS_SCRIPT}"/../files/language_packages \
sudo apt-get install -y

# Install packages
xargs -a "${PATH_TO_THIS_SCRIPT}"/../files/packages_list \
sudo apt-get install -y

# Install Chrome
if ! dpkg -l | grep chrome > /dev/null;
then
    wget \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O \
    "${TMP_DIR}"/chrome-stable.deb \
    || { echo " !!! failed to download chrome-stable !!! " | exit 2; }
    sudo dpkg -i "${TMP_DIR}"/chrome-stable.deb;
fi

# Install and configure VirtualBox and vagrant
if ! dpkg -l | grep -i virtualbox > /dev/null \
|| ! dpkg -l | grep -i vagrant > /dev/null;
then
    sudo apt-get install -y virtualbox vagrant
    nohup vagrant autocomplete install --bash > /dev/null & sleep 10
    sudo usermod -aG vboxusers "${CURRENT_USER}";
fi

# Install Docker
if ! dpkg -l | grep -i docker > /dev/null;
then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo apt-key add -
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo usermod -aG docker "${CURRENT_USER}";
fi

# Install teleport
if ! dpkg -l | grep -i teleport > /dev/null;
then
    curl https://deb.releases.teleport.dev/teleport-pubkey.asc \
    | sudo apt-key add -
    sudo add-apt-repository 'deb https://deb.releases.teleport.dev/ stable main'

    sudo apt-get update
    sudo apt-get install teleport;
fi

# Install Telegram
sudo snap install telegram-desktop

# Install VSCode
sudo snap install --classic code

# Install Slack
sudo snap install slack

# Install Discord
sudo snap install discord
