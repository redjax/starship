#!/bin/bash

##
# Script to install Starship shell on Linux/macOS (bash)
# https://starship.rs
##

CWD=$(pwd)
THIS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT=$( cd $CWD && pwd )

echo "[DEBUG] Script dir: $THIS_DIR"

function check_installed() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

function check_starship_config() {
    ## Function to check if ~/.config/starship.toml exists
    if [[ -f "$HOME/.config/starship.toml" || -L "$HOME/.config/starship.toml" ]]; then
        echo "~/.config/starship.toml exists"
        return 0
    else
        echo "~/.config/starship.toml does not exist"
        return 1
    fi
}

function backup_starship_file() {
    ## Function to handle the backup/removal of the starship.toml file
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        ## It's a regular file, backup it with .bak extension
        echo "Backing up ~/.config/starship.toml to ~/.config/starship.toml.bak"
        mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
    elif [[ -L "$HOME/.config/starship.toml" ]]; then
        ## It's a symlink, remove it
        echo "Removing symlink ~/.config/starship.toml"
        rm "$HOME/.config/starship.toml"
    fi
}

function install_starship() {
    ## Function to run Starship install script
    curl -sS https://starship.rs/install.sh | sh -s -- --yes

    if [[ $? -ne 0 ]]; then
        echo "Error installing Starship using curl script."
        exit 1
    fi

    cd $CWD
}

function update_bashrc() {
    ## Function to check and add the line to ~/.bashrc if it's missing
    local line='## Init Starship on startup
eval "$(starship init bash)"'

    ## Check if the line is already in ~/.bashrc
    if ! grep -Fxq "$line" "$HOME/.bashrc"; then
        echo "Adding Starship initialization line to ~/.bashrc"
        echo "$line" >> "$HOME/.bashrc"
    else
        echo "Starship initialization line already exists in ~/.bashrc"
    fi
}

function create_symlink() {
    ## Function to create a symlink for starship.toml
    local config_path="$HOME/.config/starship.toml"
    STARSHIP_PROFILE=${1:-"_default"}

    echo "[DEBUG] Config path: $config_path"
    echo "[DEBUG] Repository root: $REPO_ROOT"

    ## Ensure $REPO_ROOT is set
    if [[ -z "$REPO_ROOT" ]]; then
        echo "Error: REPO_ROOT is not set. Please set it to the repository's root directory."
        return 1
    fi

    ## Absolute path to the Starship profile TOML file
    local profile_path="$REPO_ROOT/configs/$STARSHIP_PROFILE.toml"

    ## Debug output
    echo "[DEBUG] Profile path: $profile_path"

    ## Check if the profile file exists
    if [[ ! -f "$profile_path" ]]; then
        echo "Error: Profile file does not exist at $profile_path."
        return 1
    fi

    ## Create the symlink
    echo "Creating symlink from $profile_path to $config_path"
    ln -sf "$profile_path" "$config_path"

    ## Confirmation
    if [[ $? -eq 0 ]]; then
        echo "Symlink created successfully."
    else
        echo "Failed to create symlink."
        return 1
    fi
}

function main() {
    ## Main function that calls the above functions in order

    ## Check if Starship is installed, store response code in variable
    check_installed "starship"
    STARSHIP_IS_INSTALLED=$?
        
    if [[ $STARSHIP_IS_INSTALLED -ne 0 ]]; then
        echo "[WARNING] Starsip is not installed. Installing starship"
        install_starship
    fi

    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Failed to install Starship."
        exit 1
    fi

    ## Check if the ~/.config/starship.toml exists
    if check_starship_config; then
        backup_starship_file
    fi
    
    ## Update ~/.bashrc with the necessary line
    update_bashrc

    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Failed to update ~/.bashrc with Starship init line."
        exit 1
    fi
    
    ## Create a symlink for starship.toml
    create_symlink

    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Failed to create symlink for starship.toml."
        exit 1
    fi
}

## Run the main function
main
