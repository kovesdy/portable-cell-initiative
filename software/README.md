# Software Development (Code Repository)
Folder for the development of software that runs on the Linux Server (either the raspberry Pi or ODroid XU-4) which controls the software-defined radio.
The configuration scripts are for Ubuntu 14.04 Server edition.

`getting_started.sh` describes how to access the Git repository and initialize the enviornment

`setup.sh` may then be run to automatically download, configure, and build the packages used for OpenBTS and GSM communciations

Edit the different variables for SDR operation, such as the band used, MCC, MNC, ARFCN, and network ShortName to customize the network and avoid interference

`start.sh` will start the OpenBTS environment and begin the system

### Features in Progress

* Web server based on Flask that handles the captive portal
* Firewall configuration to protect the network and handle the web server traffic
* RRLP tracking to enable location of handsets
* 911 service integration

### Contributing to the project

Get involved! Adding any of the features in progress is welcomed. Or, branch off. Development into 3G systems, such as the OpenBTS-UMTS package usage with software-defined radios is an exciting prospect that is yet to be explored, for example.

#### Download Ubuntu
* [ISO](http://releases.ubuntu.com/14.04/ubuntu-14.04.5-server-amd64.iso)