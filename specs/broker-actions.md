# Buddy Broker Actions Spec

This spec defines the design and behavior of the actions supported by the Buddy AI broker.

## Screen Control

- `screen_capture()`: Captures the full screen as an image.
- `window_screenshot(window_id)`: Captures a specific window as an image.

## Mouse Control

- `mouse_move(x, y)`: Moves the mouse to the specified coordinates.
- `mouse_click(button)`: Clicks the specified mouse button (1 = left, 3 = right).

## Keyboard Control

- `keyboard_type(text)`: Types the specified text.
- `keyboard_press(key)`: Presses the specified key.

## Window Management

- `window_find(title)`: Finds a window by title.
- `window_focus(window_id)`: Focuses a specific window.

## Application Control

- `app_launch(command)`: Launches an application.
- `app_close(app_name)`: Closes an application.

## System Command Execution

- `system_command(cmd)`: Executes a system command with full privileges and returns stdout/stderr.

## Policy Integration

The broker enforces the policy defined in `policy.json`, allowing or denying actions based on the current mode and consent settings.
