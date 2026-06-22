# Arch Setup

Automated setup and post-installation scripts for my Arch Linux Desktop environment

## How to use

### 1. In Arch Live System

Ensure you have an active internet connection. Then download and run the installer script:

```sh
# Install git to clone the repository
pacman -Sy git --noconfirm

# Clone repo and run archinstall wrapper
git clone https://github.com/Murmeltierchen/Arch-Setup.git setup
cd setup
./archinstall.sh
```

- Configure the disk configuration to your liking
- Create your user account
- Run the installation
- After the installation completes, reboot into your new Arch Linux system

### 2. In installed Arch Linux

Log in with your newly created user and ensure your network is connected

```sh
# Clone repo and run setup script
git clone https://github.com/Murmeltierchen/Arch-Setup.git setup
cd setup
./setup.sh
```

After an automatic reboot, your system is fully configured and ready to use

## Explanation

- `archinstall.sh`
    - Runs archinstall with the preset config `config.json`
- `setup.sh`
    - Sets up the system with some settings and programs
