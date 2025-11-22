#!/bin/bash

set -e

# Function to fetch latest release tag from GitHub repo
fetch_latest_version() {
    local repo_url="$1"
    echo "Fetching latest release version from $repo_url..." >&2

    # Get the redirect location from /releases/latest
    local latest_url=$(curl -sLI "$repo_url/releases/latest" | grep -i '^location:' | tail -1 | sed -e 's/^[Ll]ocation: //g' | tr -d '\r')

    if [ -z "$latest_url" ]; then
        echo "Error: Could not fetch latest release from $repo_url" >&2
        return 1
    fi

    # Extract tag from URL
    local tag=$(basename "$latest_url")
    echo "Latest version: $tag" >&2
    echo "$tag"
}

# Determine mode: Environment variables or command-line arguments
if [ -n "$REPO_URL" ] && [ -n "$WGT_FILE" ]; then
    # ========================================
    # Mode 1: Environment Variable Mode
    # ========================================

    echo "Running in environment variable mode"

    # TV_IP from environment or first argument
    if [ -z "$TV_IP" ] && [ -n "$1" ]; then
        TV_IP="$1"
    fi

    if [ -z "$TV_IP" ]; then
        echo "Error: TV_IP must be set as environment variable or passed as first argument"
        echo "Usage: TV_IP=<ip> REPO_URL=<repo> WGT_FILE=<file> [VERSION=<version>] $0"
        exit 1
    fi

    # VERSION is optional - fetch latest if not provided
    if [ -z "$VERSION" ]; then
        echo "VERSION not provided, fetching latest release..."
        VERSION=$(fetch_latest_version "$REPO_URL")
        DOWNLOAD_PATH="releases/latest/download"
    else
        echo "Using specified version: $VERSION"
        DOWNLOAD_PATH="releases/download/$VERSION"
    fi

    # Construct the download URL
    WGT_URL="$REPO_URL/$DOWNLOAD_PATH/$WGT_FILE"
    WGT_FILENAME="$WGT_FILE"

    # CERT_PASSWORD from environment
    CERTIFICATE_PASSWORD="${CERT_PASSWORD:-}"

elif [ -n "$1" ] && [ -n "$2" ]; then
    # ========================================
    # Mode 2: Command-Line Argument Mode (Backward Compatible)
    # ========================================

    echo "Running in command-line argument mode"

    TV_IP="$1"
    WGT_URL="$2"
    CERTIFICATE_PASSWORD="$3"

    # Extract filename from URL
    WGT_FILENAME=$(basename "$WGT_URL" | sed 's/?.*//')

    # Validate that the URL points to a .wgt file
    if [[ ! "$WGT_FILENAME" =~ \.wgt$ ]]; then
        echo "Error: The provided URL does not appear to point to a .wgt file."
        echo "URL: $WGT_URL"
        echo "Extracted filename: $WGT_FILENAME"
        exit 1
    fi

else
    echo "Error: Invalid arguments"
    echo ""
    echo "Usage Option 1 (Environment Variables):"
    echo "  TV_IP=<ip> REPO_URL=<repo_url> WGT_FILE=<file.wgt> [VERSION=<version>] [CERT_PASSWORD=<pass>] $0"
    echo ""
    echo "Usage Option 2 (Command-Line):"
    echo "  $0 <TV_IP> <WGT_URL> [CERTIFICATE_PASSWORD]"
    echo ""
    echo "Examples:"
    echo "  TV_IP=192.168.0.10 REPO_URL=https://github.com/user/repo WGT_FILE=App.wgt $0"
    echo "  TV_IP=192.168.0.10 REPO_URL=https://github.com/user/repo WGT_FILE=App.wgt VERSION=v1.0.0 $0"
    echo "  $0 192.168.0.10 https://example.com/app.wgt"
    exit 1
fi

# ========================================
# Common Installation Process
# ========================================

echo ""
echo "=========================================="
echo "  Tizen Package Installer"
echo "=========================================="
echo "TV IP:       $TV_IP"
if [ -n "$REPO_URL" ]; then
    echo "Repository:  $REPO_URL"
    echo "Version:     ${VERSION:-latest}"
fi
echo "Package URL: $WGT_URL"
echo "Package:     $WGT_FILENAME"
echo "=========================================="
echo ""

# Connect to Samsung TV
echo "Attempting to connect to Samsung TV at IP address $TV_IP"
sdb connect "$TV_IP"

# Get TV name
echo "Attempting to get the TV name..."
TV_NAME=$(sdb devices | grep -E 'device\s+\w+[-]?\w+' -o | sed 's/device//' - | xargs)

if [ -z "$TV_NAME" ]; then
    echo "Error: Unable to find the TV name."
    echo "Please ensure:"
    echo "  1. TV is in Developer Mode"
    echo "  2. TV's Host PC IP is set to this computer's IP"
    echo "  3. TV and computer are on the same network"
    exit 1
fi
echo "Found TV name: $TV_NAME"

# Download the .wgt package
echo "Downloading $WGT_FILENAME from $WGT_URL..."
wget -q --show-progress "$WGT_URL" -O "$WGT_FILENAME"
echo ""

if [ ! -f "$WGT_FILENAME" ]; then
    echo "Error: Failed to download the package."
    exit 1
fi

# Sign package if certificate is provided
if [ -n "$CERTIFICATE_PASSWORD" ]; then
    echo "Certificate password provided, attempting to sign package..."

    if [ -f /certificates/author.p12 ] && [ -f /certificates/distributor.p12 ]; then
        echo "Found certificate files, signing package..."
        sed -i "s/_CERTIFICATEPASSWORD_/$CERTIFICATE_PASSWORD/" profile.xml
        sed -i '/<\/profile>/ r profile.xml' /home/developer/tizen-studio-data/profile/profiles.xml
        tizen package -t wgt -s custom -- "$WGT_FILENAME"
    else
        echo "Error: Certificate password provided but certificate files not found."
        echo "Please mount your .p12 files at /certificates/"
        echo "Example: -v /path/to/author.p12:/certificates/author.p12"
        exit 1
    fi
else
    echo "No certificate password provided, using default dev certificate."
fi

# Install the package
echo "Installing $WGT_FILENAME to $TV_NAME..."
tizen install -n "$WGT_FILENAME" -t "$TV_NAME"

echo ""
echo "=========================================="
echo "Installation process completed!"
echo "=========================================="
