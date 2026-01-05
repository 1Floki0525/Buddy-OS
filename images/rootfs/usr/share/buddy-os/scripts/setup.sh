#!/bin/bash
# Setup script for Buddy-OS

set -euo pipefail

# Install dependencies
if command -v apt-get >/dev/null 2>&1; then
    echo "Installing system dependencies..."
    apt-get update
    apt-get install -y \
        python3-pip \
        python3-dev \
        python3-gi \
        gir1.2-gtk-3.0 \
        xdotool \
        scrot \
        imagemagick \
        docker.io

    # Install pip dependencies
    echo "Installing Python dependencies..."
    pip3 install --user \
        pyscreenshot \
        pyautogui \
        pynput \
        requests

elif command -v yum >/dev/null 2>&1; then
    echo "Installing system dependencies (CentOS/RHEL)..."
    yum install -y \
        python3-pip \
        python3-devel \
        gtk3 \
        xdotool \
        scrot \
        ImageMagick \
        docker

    # Install pip dependencies
    echo "Installing Python dependencies..."
    pip3 install --user \
        pyscreenshot \
        pyautogui \
        pynput \
        requests

else
    echo "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

# Verify installation
echo "\nVerifying installations..."

# Check Python modules
python3 -c "import gi; import pyscreenshot; import pyautogui; import pynput; import requests" && echo "✅ Python modules installed" || echo "❌ Python modules installation failed"

# Check system tools
command -v xdotool >/dev/null 2>&1 && echo "✅ xdotool installed" || echo "❌ xdotool not found"
command -v docker >/dev/null 2>&1 && echo "✅ docker installed" || echo "❌ docker not found"

echo "\nInstallation complete!"
