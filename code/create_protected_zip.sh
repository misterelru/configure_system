#!/bin/bash

# Set variables
CURRENT_USER=$(whoami)
HOMEDIR=$( getent passwd "${CURRENT_USER}" | cut -d: -f6 )
PATH_TO_THIS_SCRIPT=$(dirname "$0")

# Make a tmp directory
if ! test -d "${PATH_TO_THIS_SCRIPT}"/../tmp;
then
    mkdir "${PATH_TO_THIS_SCRIPT}"/../tmp;
fi

# Create a directory for ssh keys
mkdir "${PATH_TO_THIS_SCRIPT}"/../tmp/ssh

# Pack keys in an proteckted archive
cp -R "${HOMEDIR}"/.ssh/* "${PATH_TO_THIS_SCRIPT}"/../tmp/ssh
zip --encrypt -r "${PATH_TO_THIS_SCRIPT}"/../files/ssh-folder.zip \
"${PATH_TO_THIS_SCRIPT}"/../tmp/ssh
