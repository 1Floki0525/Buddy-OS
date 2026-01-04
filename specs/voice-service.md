# Buddy Voice Service Spec

This spec defines the design and behavior of the Buddy Voice service.

## Wake Word Detection

- Listens continuously for the "Hey Buddy" wake word.
- Uses the Vosk speech recognition engine for offline, real-time detection.

## Speech-to-Text

- Transcribes spoken commands to text in real-time.
- Uses the Vosk model for accurate transcription.

## Command Execution

- Sends transcribed commands to Buddy Copilot for execution.
- Integrates with the broker API for full system control.

## Behavior

- The service runs in the background as a daemon.
- Automatically starts at boot via systemd.
- Logs recognized commands and execution results.

## Future Enhancements

- Add support for multiple languages.
- Implement noise cancellation for better accuracy.
- Add voice feedback (e.g., "Command executed").
