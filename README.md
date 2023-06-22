# configure_system

This script is for configuring your system ( Ubuntu 20.04 ) after installation.
You can run it with options.
If you want to run a configuring system with full parameters for A.Osipov, run this with the -f option.
If you want a simple setup for other users, run this with the -s option.

In simple mode:
Will be upgraded all system packages.
It will install packages for work, run the script to change the gdm color, and enable autorun for ssh-agent if you respond yes in the user dialog.

In full mode:
Will install all from a simple configuring,
and will install apps: vanilla-gnome, wireshark, winbox, configure git, copied ssh-keys if you respond yes in the user dialog,
will be mounted the Google Drive, and copy a database from it.
