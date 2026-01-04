#!/bin/bash
# Launch Buddy Copilot GUI

# Set environment variables for GTK
export GDK_BACKEND=x11
export GTK_THEME=Adwaita

# Navigate to buddy-copilot directory
cd "$(dirname "$0")"

# Install dependencies if needed
if ! python3 -c "import gi" &>/dev/null; then
    echo "Installing dependencies..."
    pip3 install -r requirements.txt
fi

# Launch the application
python3 -m buddy_copilot
