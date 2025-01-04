#!/bin/bash

##
# Script to install Starship shell on Linux/macOS (bash)
# https://starship.rs
##

CWD=$(pwd)
THIS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT=$( cd $CWD && pwd )
# ## echo "[DEBUG] Script dir: $THIS_DIR"
# ## echo "[DEBUG] Repository root: $REPO_ROOT"

NERDFONT="FiraMono"
NERDFONT_DOWNLOAD_URL_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
# ## echo "[DEBUG] NerdFont download URL base: $NERDFONT_DOWNLOAD_URL"

function check_installed() {
    ## Check if a command resolves/does not error
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

function show_profiles() {
    ## Function to recursively find all .toml files in $REPO_ROOT/configs
    #  and display them without the .toml extension

    local profiles_path="$REPO_ROOT/configs"

    ## Ensure $profiles_path exists
    if [[ ! -d "$profiles_path" ]]; then
        echo "[ERROR] Configs directory not found at $profiles_path"
        return 1
    fi

    ## Find all .toml files in the directory and subdirectories
    echo "Available profiles:"
    find "$profiles_path" -type f -name "*.toml" | while read -r file; do
        ## Remove the directory path and the .toml extension
        profile_name=$(basename "$file" .toml)
        echo " - $profile_name"
    done
}

function install_nerdfont() {
    local FONT_NAME=${1:-$NERDFONT}
    ## echo "[DEBUG] NerdFont name: $FONT_NAME"
    local FONT_DOWNLOAD_URL="$NERDFONT_DOWNLOAD_URL_BASE/$FONT_NAME.zip"
    ## echo "[DEBUG] NerdFont download URL: $FONT_DOWNLOAD_URL"
    local TEMP_DIR=$(mktemp -d)
    ## echo "[DEBUG] Temporary directory: $TEMP_DIR"
    local FONT_DIR="$HOME/.local/share/fonts"
    ## echo "[DEBUG] Fonts directory: $FONT_DIR"
    local EXTRACT_DIR="$FONT_DIR/$FONT_NAME"
    ## echo "[DEBUG] Font extraction path: $EXTRACT_DIR"

    if [[ -d "$EXTRACT_DIR" ]]; then
        echo "NerdFont '$FONT_NAME' is already installed."
        return
    fi

    ZIP_INSTALLED=$(check_installed "unzip")
    if [[ $ZIP_INSTALLED -ne 0 ]]; then
        echo "[ERROR] zip/unzip utility is not installed. Cannot extract NerdFont."
        exit 1
    fi

    FCCACHE_INSTALLED=$(check_installed "fc-cache")
    if [[ $FCCACHE_INSTALLED -ne 0 ]]; then
        echo "[ERROR] fc-cache utility is not installed. Cannot install NerdFont."
        exit 1
    fi

    echo "Downloading NerdFont: $FONT_NAME"
    curl -Lo "$TEMP_DIR/$FONT_NAME.zip" "$FONT_DOWNLOAD_URL"
    if [[ $? -ne 0 ]]; then
        echo "Error downloading NerdFont: $FONT_NAME"
        rm -rf "$TEMP_DIR"

        exit 1
    fi
    echo "NerdFont downloaded successfully."

    if [[ ! -d "$EXTRACT_DIR" ]]; then
        echo "[WARNING] Font extraction path '$EXTRACT_DIR' does not exist. Creating it."
        mkdir -p "$EXTRACT_DIR"
    fi

    echo "Extracting NerdFont: $FONT_NAME"
    unzip "$TEMP_DIR/$FONT_NAME.zip" -d "$EXTRACT_DIR"
    if [[ $? -ne 0 ]]; then
        echo "Error extracting NerdFont: $FONT_NAME"
        rm -rf "$TEMP_DIR"

        exit 1
    fi
    echo "NerdFont extracted successfully."

    echo "Updating font cache..."
    fc-cache -fv > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Error updating font cache."
        rm -rf "$TEMP_DIR"

        exit 1
    fi
    echo "Font cache updated successfully."

    ## Clean up temporary files
    rm -rf "$TEMP_DIR"
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

    ## echo "[DEBUG] Config path: $config_path"

    ## Ensure $REPO_ROOT is set
    if [[ -z "$REPO_ROOT" ]]; then
        echo "Error: REPO_ROOT is not set. Please set it to the repository's root directory."
        return 1
    fi

    ## Absolute path to the Starship profile TOML file
    local profile_path="$REPO_ROOT/configs/$STARSHIP_PROFILE.toml"

    ## Debug output
    ## echo "[DEBUG] Profile path: $profile_path"

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

    install_nerdfont

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
# main

show_profiles
