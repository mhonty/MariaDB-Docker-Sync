#!/bin/bash

REPO_URL="https://github.com/mhonty/MariaDB-Docker-Sync.git"
SCRIPT_NAME="sync_db.sh"
GLOBAL_CONFIG_DIR="/etc/sync-db"
LOCAL_CONFIG_DIR="$HOME/.config/sync-db"
GLOBAL_INSTALL_DIR="/usr/local/bin"
LOCAL_INSTALL_DIR="$HOME/bin"

# Check if the script is run as root
if [ "$(id -u)" -eq 0 ]; then
    echo "This script should not be run as root. Aborting installation."
    exit 1
fi

# Check write permissions on /etc/ and /usr/local/bin
if [ -w "/etc/" ] && [ -w "/usr/local/bin/" ]; then
    echo "Detected sufficient permissions for global installation."
    echo "Do you want to install globally or for the current user only?"
    echo "1. Globally"
    echo "2. Locally (for the current user)"
    read -p "Enter choice [1 or 2]: " choice

    if [ "$choice" -eq 1 ]; then
        INSTALL_DIR=$GLOBAL_INSTALL_DIR
        CONFIG_DIR=$GLOBAL_CONFIG_DIR
        USE_SUDO=true
    else
        INSTALL_DIR=$LOCAL_INSTALL_DIR
        CONFIG_DIR=$LOCAL_CONFIG_DIR
        USE_SUDO=false
    fi
else
    echo "No sufficient permissions detected for global installation."
    echo "Do you want to install locally (for the current user) or abort?"
    echo "1. Install locally"
    echo "2. Abort"
    read -p "Enter choice [1 or 2]: " choice

    if [ "$choice" -eq 1 ]; then
        INSTALL_DIR=$LOCAL_INSTALL_DIR
        CONFIG_DIR=$LOCAL_CONFIG_DIR
        USE_SUDO=false
    else
        echo "Installation aborted."
        exit 1
    fi
fi

# Create the installation directory if it does not exist
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    if [ "$USE_SUDO" = true ]; then
        sudo chown "$USER:$USER" "$INSTALL_DIR"
    fi
    echo "Installation directory created at $INSTALL_DIR."
fi

# Clone the repository
echo "Cloning repository..."
git clone "$REPO_URL" "/tmp/MariaDB-Docker-Sync"

# Set executable permissions for the script
echo "Setting executable permissions for $SCRIPT_NAME..."
chmod +x "/tmp/MariaDB-Docker-Sync/$SCRIPT_NAME"

# Move the script to the installation directory
if [ "$USE_SUDO" = true ]; then
    sudo mv "/tmp/MariaDB-Docker-Sync/$SCRIPT_NAME" "$INSTALL_DIR/sync_db"
else
    mv "/tmp/MariaDB-Docker-Sync/$SCRIPT_NAME" "$INSTALL_DIR/sync_db"
fi

# Create the configuration directory if it does not exist
if [ ! -d "$CONFIG_DIR" ]; then
    if [ "$USE_SUDO" = true ]; then
        sudo mkdir -p "$CONFIG_DIR"
        sudo chown "$USER:$USER" "$CONFIG_DIR"
    else
        mkdir -p "$CONFIG_DIR"
    fi
    echo "Configuration directory created at $CONFIG_DIR."
fi

# Add ~/bin to PATH if installing locally and ~/bin is not in PATH
if [ "$INSTALL_DIR" = "$LOCAL_INSTALL_DIR" ]; then
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        source "$HOME/.bashrc"
        echo "Added $HOME/bin to PATH."
    fi
fi

echo "Installation complete. You can now run the script using the command 'sync_db'."
