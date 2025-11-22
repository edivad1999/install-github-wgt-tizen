#!/bin/bash

if [ -z "$1" ]; then
    echo "Error: Please provide the IP address of your Samsung TV as the first argument."
    echo "Usage: $0 <TV_IP> <WGT_URL> [CERTIFICATE_PASSWORD]"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Error: Please provide the URL to the .wgt file as the second argument."
    echo "Usage: $0 <TV_IP> <WGT_URL> [CERTIFICATE_PASSWORD]"
    exit 1
fi

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

echo ""
echo "=========================================="
echo "  Tizen Package Installer"
echo "=========================================="
echo "TV IP:       $TV_IP"
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
echo "Downloading $WGT_FILENAME..."
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
