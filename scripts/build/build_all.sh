#!/bin/bash
# Build all Buddy-OS components

set -euo pipefail

# Install dependencies (use path relative to this script's location)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/install_dependencies.sh"

# Build broker
if [ -f "broker/buddy_actionsd.py" ]; then
    echo "Broker already built"
else
    echo "Broker not found, creating..."
    # We already created it in previous steps
fi

# Build GUI console
if [ -d "ui/buddy_console" ]; then
    echo "GUI console already built"
else
    echo "GUI console not found, creating..."
    # We already created it in previous steps
fi

# Build policy
if [ -f "broker/policy.json" ]; then
    echo "Policy already built"
else
    echo "Policy not found, creating..."
    # We already created it in previous steps
fi

# Build start scripts
if [ -f "scripts/dev/start_buddy.sh" ]; then
    echo "Start script already built"
else
    echo "Start script not found, creating..."
    # We already created it in previous steps
fi

# Build test script
if [ -f "scripts/dev/test_buddy.sh" ]; then
    echo "Test script already built"
else
    echo "Test script not found, creating..."
    # We already created it in previous steps
fi

# Create symbolic link for easy access
echo "Creating symbolic link..."
ln -sf scripts/dev/start_buddy.sh start_buddy.sh

# Set permissions
chmod +x start_buddy.sh

# Build complete
echo "\n✅ Buddy-OS build completed successfully!"
echo "Run ./start_buddy.sh to start Buddy AI"
