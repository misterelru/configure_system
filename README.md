# configure_system

This script is for setting up your system ( Ubuntu 20.04 ) after installation.
You can run it with options.
If you want a full setup system for A.Osipov run this with the -f option.
If you want a simple setup for other users run this with the -s option.

In simple setup:
Will be upgraded all system packages.
It will be installed packages for work.
Will run the script to change the gdm color.
Will be enabled autorun for ssh-agent if you respond yes in the user dialog.

In full setup:
Will be installed all from a simple setup.
Will be installed vanilla-gnome, wireshark, winbox, and configured git, and copied ssh-keys if you responded yes in the user dialog.
Will be mounted the google drive and copy database from it
