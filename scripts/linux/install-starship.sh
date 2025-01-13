#!/bin/bash

##
# Script to install Starship shell on Linux/macOS (bash)
# https://starship.rs
##

CWD=$(pwd)
THIS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "[DEBUG] Script dir: $THIS_DIR"
