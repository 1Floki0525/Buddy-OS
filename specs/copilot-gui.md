# Buddy Copilot GUI Spec

This spec defines the design and behavior of the Buddy Copilot GUI app.

## Position

The app is positioned in the **bottom-right corner** of the desktop. This allows users to easily access it while keeping it out of the way during normal development.

## Features

- **Text Input Field**: Users can type commands to interact with Buddy AI.
- **Voice Activation Button**: Clicking this button or saying "Hey Buddy" triggers voice activation.
- **Scrollable Log Area**: Displays live task progress, allowing users to watch Buddy execute tasks on-screen.

## Behavior

- When a command is entered, it is sent to the Buddy AI for execution.
- The log area updates in real-time with task progress.
- The app remains open and responsive, allowing users to interrupt or modify Buddy’s actions.

## Future Enhancements

- Add a **terminal widget** for shared dev console.
- Integrate with **Accessibility APIs** for screen observation.
- Add **error handling** and **feedback** mechanisms.
