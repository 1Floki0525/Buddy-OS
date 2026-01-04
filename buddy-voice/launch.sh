#!/bin/bash
# Launch Buddy Voice Service

# Set environment variables
export PYAUDIO_INPUT_DEVICE=0  # Default microphone

# Navigate to buddy-voice directory
cd "$(dirname "$0")"

# Install dependencies if needed
if ! python3 -c "import requests" &>/dev/null; then
    echo "Installing dependencies..."
    pip3 install -r requirements.txt
fi

# Launch the application
python3 -m buddy_voice
