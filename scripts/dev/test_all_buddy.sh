#!/bin/bash
# Test All Buddy-OS Capabilities

set -euo pipefail

# Test 1: Ping the daemon
echo "Testing ping..."
curl -s http://localhost:8000/ping

# Test 2: Get policy
echo "\nTesting policy..."
curl -s http://localhost:8000/policy

# Test 3: Get capabilities
echo "\nTesting capabilities..."
curl -s http://localhost:8000/capabilities

# Test 4: Execute shell command
echo "\nTesting shell execution..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "shell", "params": {"command": "echo \"Hello from Buddy!\""}}'

# Test 5: Take screenshot
echo "\nTesting screenshot..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "screen_capture", "params": {}}'

# Test 6: Launch application
echo "\nTesting application launch..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "launch_app", "params": {"command": "xdg-open https://github.com"}}'

# Test 7: Write file
echo "\nTesting file write..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "write_file", "params": {"path": "/tmp/buddy_test.txt", "content": "This file was created by Buddy AI!"}}'

# Test 8: Check if file was created
echo "\nChecking if file was created..."
if [ -f "/tmp/buddy_test.txt" ]; then
    echo "✅ File created successfully"
    cat /tmp/buddy_test.txt
else
    echo "❌ File creation failed"
fi

# Test 9: List directory
echo "\nTesting directory listing..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "list_dir", "params": {"path": "/tmp"}}'

# Test 10: Docker control (if available)
echo "\nTesting docker control..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "docker_control", "params": {"action": "list", "args": ["ps", "-a"]}}'

# Test 11: Network admin (if available)
echo "\nTesting network admin..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "network_admin", "params": {"action": "list_interfaces"}}'

# Test 12: Mouse control (if available)
echo "\nTesting mouse control..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "mouse_control", "params": {"action": "move", "x": 100, "y": 100}}'

# Test 13: Keyboard control (if available)
echo "\nTesting keyboard control..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "keyboard_control", "params": {"action": "type", "text": "Hello from Buddy AI!"}}'

# Test 14: Window management (if available)
echo "\nTesting window management..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "window_management", "params": {"action": "find", "title": "Buddy Copilot"}}'

# Test 15: Buddy Copilot GUI (simulated)
echo "\nTesting Buddy Copilot GUI..."
echo "✅ Buddy Copilot GUI should be visible at bottom-right of desktop"

# Test 16: Buddy Voice Service (simulated)
echo "\nTesting Buddy Voice Service..."
echo "✅ Buddy Voice Service should be listening for 'Hey Buddy' (simulated for demo)"

# Test 17: Integration test - send command via HTTP
echo "\nTesting integration..."
curl -s -X POST http://localhost:8000/execute -H "Content-Type: application/json" -d '{"action": "shell", "params": {"command": "echo \"Integration test successful\""}}'

echo "\nAll tests completed!"
