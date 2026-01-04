#!/bin/bash
# Start Buddy-OS Services

set -euo pipefail

# Start Buddy Actions Daemon
echo "Starting Buddy Actions Daemon..."
(nohup python3 broker/buddy_actionsd.py > broker/buddy_actionsd.log 2>&1 &)

# Start Buddy Console GUI
echo "Starting Buddy Console..."
ui/buddy_console/launch.sh &

# Start Buddy Voice Service (placeholder)
echo "Starting Buddy Voice Service..."
# In a real implementation, this would start the voice service
# For now, just log that it's starting
(nohup echo "Buddy Voice Service started (placeholder)" > broker/buddy_voice.log 2>&1 &)

# Wait for services to start
sleep 2

# Print status
echo "\nBuddy-OS Services Started:"
echo "- Actions Daemon: http://localhost:8000"
echo "- Console GUI: Running in background"
echo "- Voice Service: Placeholder running"

# Test connection to actions daemon
if curl -s http://localhost:8000/ping > /dev/null; then
    echo "✅ Actions Daemon is running"
else
    echo "❌ Actions Daemon failed to start"
fi

# Test capabilities
if curl -s http://localhost:8000/capabilities | grep -q "screen_control"; then
    echo "✅ Full system capabilities enabled"
else
    echo "❌ Capabilities not available"
fi

echo "\nBuddy is ready to assist you!"
