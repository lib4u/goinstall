#!/bin/bash

set -e  # Stop script on error

LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
GO_TAR="$LATEST_VERSION.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/$GO_TAR"

# Detect package manager and remove old Go installation
if command -v go &> /dev/null; then
    echo "Removing old version of Go..."
    if command -v dnf &> /dev/null; then
        sudo dnf remove -y golang || true
    elif command -v apt &> /dev/null; then
        sudo apt remove -y golang || true
    elif command -v pacman &> /dev/null; then
        sudo pacman -Rns --noconfirm go || true
    elif command -v zypper &> /dev/null; then
        sudo zypper remove -y golang || true
    fi
fi

# Remove old manually installed version
if [ -d "/usr/local/go" ]; then
    echo "Removing old Go installation from /usr/local/go..."
    sudo rm -rf /usr/local/go
fi

# Download new version
echo "Downloading the latest version of Go $LATEST_VERSION from $GO_URL"
wget "$GO_URL"

# Extract Go to /usr/local
echo "Extracting Go..."
sudo tar -C /usr/local -xzf "$GO_TAR"

# Remove downloaded archive
rm "$GO_TAR"

# Configure environment variables
PROFILE_FILE="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    PROFILE_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    PROFILE_FILE="$HOME/.bashrc"
elif [ -f "$HOME/.profile" ]; then
    PROFILE_FILE="$HOME/.profile"
fi

echo "Updating environment variables..."
{
    echo "export PATH=\$PATH:/usr/local/go/bin"
    echo "export GOPATH=\$HOME/go"
    echo "export PATH=\$PATH:\$GOPATH/bin"
} >> "$PROFILE_FILE"

echo "Sourcing $PROFILE_FILE..."
source "$PROFILE_FILE" || { echo "Error sourcing $PROFILE_FILE"; exit 1; }
echo "$PROFILE_FILE sourced successfully."

echo "Go has been successfully updated to version:"
go version
