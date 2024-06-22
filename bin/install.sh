#!/bin/bash
# Script to install the sync_db script
# This script will install the sync_db script from the GitHub repository
#
# Usage:
#   bash install.sh
#   bash install.sh --uninstall | --remove
#   bash install.sh -h | --help
#   bash install.sh -v | --version
#
# Options:
#   --uninstall, --remove   Uninstalls the sync_db script and its configuration
#   -h, --help              Show this help message and exit
#   -v, --version           Show the installer version and exit
#
# Exit codes:
#   0   - Successful installation or uninstallation
#   1   - Error during installation or uninstallation
#   2   - Invalid command-line option
#

# Function to check dependencies
check_dependencies() {
    echo "Checking dependencies..."
    local missing_deps=0
    local install_list=""

    # Check for netcat
    command -v nc >/dev/null 2>&1 || { echo >&2 "netcat is required but it's not installed."; missing_deps=1; install_list="$install_list nc"; }

    # Check for sshpass
    command -v sshpass >/dev/null 2>&1 || { echo >&2 "sshpass is required but it's not installed."; missing_deps=1; install_list="$install_list sshpass"; }

    # Check for git
    command -v git >/dev/null 2>&1 || { echo >&2 "git is required but it's not installed."; missing_deps=1; install_list="$install_list git"; }

    # Check for curl or wget
    command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || { echo >&2 "Either curl or wget is required but neither is installed."; missing_deps=1; install_list="$install_list curl"; }
    
    # If dependencies are missing, attempt to install them
    if [ $missing_deps -ne 0 ]; then
        echo "Missing dependencies: $install_list"
        echo "Do you want to install the missing packages? [y/N]"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            if command -v apt-get >/dev/null; then
                sudo apt-get update && sudo apt-get install -y $install_list
            elif command -v yum >/dev/null; then
                sudo yum install -y $install_list
            elif command -v zypper >/dev/null; then
                sudo zypper install -y $install_list
            else
                echo "Automatic installation not supported on this system. Please install the missing packages manually."
                exit 1
            fi
        else
            echo "User declined installation. Exiting..."
            exit 1
        fi
    else
        echo "All dependencies are met."
        echo
        echo
    fi
}
# Clone the repository
clone_repository() {
    log_message "Cloning repository..."
    if [ -d $TEMP_DIR ]; then
        rm -rf $TEMP_DIR
    fi

    if ! git clone $REPO_URL $TEMP_DIR >/dev/null 2>&1; then
        log_message "Error cloning repository. Aborting installation."
        cleanup
        exit 1
    fi

    # Iniciar el contador y esperar hasta que el directorio esté disponible o se alcancen los 10 segundos
    local wait_time=0
    while [ ! -d $TEMP_DIR/bin ]; do
        sleep 1
        wait_time=$((wait_time + 1))
        if [ "$wait_time" -ge 10 ]; then
            log_message "Timeout reached while waiting for the bin directory to appear. Aborting installation."
            cleanup
            exit 1
        fi
    done

    log_message "Setting executable permissions for $SCRIPT_NAME..."
    chmod +x $TEMP_DIR/bin/*
    if ! mkdir -p $INSTALL_DIR/$SCRIPT_NAME; then
        log_message "Error creating installation directory. Aborting installation."
        cleanup
        exit 1
    fi
    if ! mv $TEMP_DIR/* $INSTALL_DIR/$SCRIPT_NAME/; then
        log_message "Error moving scripts to $INSTALL_DIR. Aborting installation."
        cleanup
        exit 1
    fi
    if ! ln $INSTALL_DIR/$SCRIPT_NAME/bin/sync_db $INSTALL_DIR/sync_db; then
    log_message "Error creating hard link for sync_db. Aborting installation."
    cleanup
    exit 1
    fi
    if ! ln $INSTALL_DIR/$SCRIPT_NAME/bin/uninstall_sync_db $INSTALL_DIR/uninstall_sync_db; then
    log_message "Error creating hard link for sync_db. Aborting installation."
    cleanup
    exit 1
    fi
}

# Helper function to log messages
log_message() {
    if [ ! -z $LOG_DIR ] && [ ! -d $LOG_DIR ]; then
        mkdir -p $LOG_DIR
        echo $(date +'%Y-%m-%d %H:%M:%S') - $1 | tee -a $LOG_FILE
    elif [ -d "$LOG_DIR" ]; then
        echo $(date +'%Y-%m-%d %H:%M:%S') - $1 | tee -a $LOG_FILE
    fi

}
# Cleanup function to remove partial installations
cleanup() {
    exit 1;
    log_message "Performing cleanup..."
    [ -d $TEMP_DIR ] && rm -rf $TEMP_DIR
    [ -f $INSTALL_DIR/$SCRIPT_NAME ] && rm -f $INSTALL_DIR/$SCRIPT_NAME
    log_message "Cleanup completed."
}
# Uninstall function to remove installed files
uninstall() {
    display_header_uninstall  # Display an uninstallation header, assuming the function is defined

    # Check for the script's installation locations and prompt the user if both are present.
    local local_location="${LOCAL_INSTALL_DIR}/${SCRIPT_NAME}/bin/${SCRIPT_NAME}"
    local global_location="${GLOBAL_INSTALL_DIR}/${SCRIPT_NAME}/bin/${SCRIPT_NAME}"
    local choice

    if [ -f "$local_location" ] && [ -f "$global_location" ]; then
        echo "Both local and global installations are found."
        PS3="Enter your choice (1, 2, or 3): "

        options=("Uninstall local version" "Uninstall global version" "Cancel")
        select opt in "${options[@]}"
        do
            case $REPLY in
                1) 
                    location="$local_location"
                    config_dir="$LOCAL_CONFIG_DIR"
                    log_dir="$LOG_DIR"
                    INSTALL_DIR="$LOCAL_INSTALL_DIR"
                    use_sudo=false
                    break
                    ;;
                2) 
                    location="$global_location"
                    config_dir="$GLOBAL_CONFIG_DIR"
                    log_dir="$GLOBAL_LOG_DIR"
                    INSTALL_DIR="$GLOBAL_INSTALL_DIR"
                    use_sudo=true
                    break
                    ;;
                3) 
                    echo "Uninstallation cancelled."
                    exit 0
                    ;;
                *) 
                    echo "Invalid choice. Please enter 1, 2, or 3."
                    ;;
            esac
        done
    elif [ -f "$local_location" ]; then
        location="$local_location"; config_dir="$LOCAL_CONFIG_DIR"; log_dir="$LOG_DIR"; use_sudo=false
        INSTALL_DIR="$LOCAL_INSTALL_DIR"
    elif [ -f "$global_location" ]; then
        location="$global_location"; config_dir="$GLOBAL_CONFIG_DIR"; log_dir="$GLOBAL_LOG_DIR"; use_sudo=true
        INSTALL_DIR="$GLOBAL_INSTALL_DIR"
    else
        echo "No installation found. Nothing to uninstall."
        exit 1
    fi

    # Proceed with the chosen uninstallation option
    if [ "$use_sudo" = true ]; then
        if [ "$(id -u)" -ne 0 ]; then
            echo "Administrator permissions are required for global uninstallation."
            sudo -v
            if [ $? -ne 0 ]; then
                echo "Administrator permissions not granted. Uninstallation aborted."
                exit 1
            fi
        fi
        sudo rm -rf "$INSTALL_DIR/$SCRIPT_NAME"
        sudo rm -rf "$config_dir"
        sudo rm -rf "$log_dir"
    else
        rm -f "$location"
        rm -rf "$config_dir"
        rm -rf "$log_dir"
    fi

    echo "${SCRIPT_NAME} has been uninstalled from $(dirname "$location")."
    exit 0
}
# Display help message
display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --uninstall      Uninstall the ${SCRIPT_NAME} script and its configuration"
    echo "  -h, --help       Show this help message and exit"
    exit 0
}
# Function to display the version
display_version() {
    echo "${SCRIPT_NAME} installer version ${SCRIPT_VERSION}"
    exit 0
}
# Function to display the header
display_header() {
    echo "=================================="
    echo "       ${SCRIPT_NAME} installer"
    echo "=================================="
    echo
}
# Function to display the uninstallation header
display_header_uninstall() {
    echo "=================================="
    echo    "${SCRIPT_NAME} uninstaller"
    echo "=================================="
    echo
}
# Function to get the latest version of the script
get_latest_version() {
    if command -v curl > /dev/null 2>&1; then
        FETCH_COMMAND="curl -s"
    elif command -v wget > /dev/null 2>&1; then
        FETCH_COMMAND="wget -qO-"
    else
        echo "Error: curl or wget is required to fetch the latest version. Please install either curl or wget and try again."
        exit 1
    fi

    # Retrieve the latest script version from GitHub tags using the available tool
    SCRIPT_VERSION=$($FETCH_COMMAND https://api.github.com/repos/${USER_OWNER}/${REPO_NAME}/tags | grep -m 1 '"name"' | awk -F '"' '{print $4}')
}

# Constants
USER_OWNER="mhonty"
REPO_NAME="MariaDB-Docker-Sync"
REPO_URL="https://github.com/${USER_OWNER}/${REPO_NAME}.git"
SCRIPT_NAME="sync_db"
GLOBAL_CONFIG_DIR="/etc/${SCRIPT_NAME}"
LOCAL_CONFIG_DIR="$HOME/.config/${SCRIPT_NAME}"
GLOBAL_INSTALL_DIR="/usr/local/bin"
LOCAL_INSTALL_DIR="$HOME/bin"
TEMP_DIR="/tmp/${REPO_NAME}"
LOCAL_LOG_DIR="$HOME/.logs"
LOCAL_LOG_FILE="$LOCAL_LOG_DIR/${SCRIPT_NAME}.log"
GLOBAL_LOG_DIR="/etc/logs/${SCRIPT_NAME}"
GLOBAL_LOG_FILE="$GLOBAL_LOG_DIR/${SCRIPT_NAME}.log"

# Check if the script is run as root
if [ "$(id -u)" -eq 0 ] && [ -z "$SUDO_USER" ]; then
    display_header
    echo "This script should not be run as root. Aborting installation."
    exit 1
fi

# Validate parameters max 1
    if [ $# -gt 1 ]; then
        echo "Invalid number of arguments. Use -h or --help for usage information."
        exit 1
    fi

    # Parse command-line options
    case "$1" in
        --remove|--uninstall)
            uninstall
            ;;
        -h|--help)
            get_latest_version
            display_header
            display_help
            ;;
        -v|--version)
            get_latest_version
            display_header
            display_version
            ;;
        "")
            get_latest_version
            display_header
            check_dependencies
            ;;
        *)
            get_latest_version
            display_header
            echo "Unknown option: $1. Use -h or --help for usage information."
            exit 1
            ;;
    esac

# Display welcome message with version
echo "Welcome to the ${SCRIPT_NAME} installer!"
echo "Installing version ${SCRIPT_VERSION}..."
echo "-----------------------------------------"


# Determine installation directory based on permissions
if [ -w "/etc/" ] && [ -w "/usr/local/bin/" ]; then
    echo "Detected sufficient permissions for global installation."
    echo "Select the installation type:"
    PS3="Enter choice [1 or 2]: "

    options=("Globally" "Locally (for the current user) " "Abort")
    select opt in "${options[@]}"
    do
        case $REPLY in
            1) 
                INSTALL_DIR=$GLOBAL_INSTALL_DIR
                CONFIG_DIR=$GLOBAL_CONFIG_DIR
                USE_SUDO=true
                LOG_DIR=$GLOBAL_LOG_DIR
                LOG_FILE=$GLOBAL_LOG_FILE
                mkdir -p "$LOG_DIR"
                chown root:root "$LOG_DIR"
                touch "$LOG_FILE"
                chmod 666 "$LOG_FILE"
                break
                ;;
            2) 
                INSTALL_DIR=$LOCAL_INSTALL_DIR
                CONFIG_DIR=$LOCAL_CONFIG_DIR
                USE_SUDO=false
                LOG_DIR=$LOCAL_LOG_DIR
                mkdir -p "$LOG_DIR"
                LOG_FILE=$LOCAL_LOG_FILE
                touch "$LOG_FILE"
                break
                ;;
            3) 
                echo 
                echo
                echo "Installation aborted."
                cleanup
                exit 1
                ;;
            *) 
                echo "Invalid choice. Please select 1 or 2."
                ;;
        esac
    done

else
    echo "Insufficient permissions detected for global installation."
    echo "Select an option:"
    PS3="Enter choice [1 or 2]: "

    options=("Install locally (for the current user)" "Abort")
    select opt in "${options[@]}"
    do
        case $REPLY in
            1) 
                INSTALL_DIR=$LOCAL_INSTALL_DIR
                CONFIG_DIR=$LOCAL_CONFIG_DIR
                USE_SUDO=false
                LOG_DIR=$LOCAL_LOG_DIR
                LOG_FILE=$LOCAL_LOG_FILE
                break
                ;;
            2) 
                echo "Installation aborted."
                cleanup
                exit 1
                ;;
            *) 
                echo "Invalid choice. Please select 1 or 2."
                ;;
        esac
    done

fi

clone_repository

# Create the installation directory if it does not exist
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p $INSTALL_DIR
    if [ "$USE_SUDO" = true ]; then
        chown root:root $INSTALL_DIR/$SCRIPT_NAME
        chmod 755 $INSTALL_DIR/$SCRIPT_NAME
    else 
        # Add ~/bin to PATH if installing locally and ~/bin is not in PATH
            if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
                echo 'export PATH="$HOME/bin:$PATH"' >> $HOME/.bashrc
                source $HOME/.bashrc
                log_message "Added $HOME/bin to PATH."
            fi
    fi
    log_message "Installation directory created at $INSTALL_DIR."
fi

# Move the scripts to the installation directory


# Create the configuration directory if it does not exist
if [ ! -d "$CONFIG_DIR" ]; then
    if [ "$USE_SUDO" = true ]; then
        mkdir -p $CONFIG_DIR
        chown root:root $CONFIG_DIR
        chmod 666 $CONFIG_DIR
    else
        mkdir -p $CONFIG_DIR
    fi
    log_message "Configuration directory created at $CONFIG_DIR."
fi


log_message "Installation complete. You can now run the script using the command '${SCRIPT_NAME}'."
echo "Installation complete. You can now run the script using the command '${SCRIPT_NAME}'."
echo "You can remove the script using the command 'uninstall_${SCRIPT_NAME}'."
