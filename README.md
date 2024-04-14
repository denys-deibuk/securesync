# SecureSync 🌐

This is an installation script for RPM-based distributions that sets up SFTP and FRP services to access the server behind the NAT using a mobile application.

## Prerequisites

The following dependencies should be installed and available on the `PATH`. 
Refer to the documentation for the installation instructions:
```
gum
openssh-server
frpc
```

## Installation

Clone this repository and make `install.sh` executable by running:
```bash
sudo chmod +x ./install.sh
```
Run `install.sh` with sudo privileges and follow the instructions:
```bash
sudo ./install.sh
```
