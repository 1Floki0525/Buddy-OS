# Buddy Voice Service Spec

This spec defines the design and behavior of the Buddy Voice service.

## Wake Word Detection

<<<<<<< HEAD
- Uses YOLO VAD for voice activity detection.
- Listens continuously for voice commands.

## Speech-to-Text

- Transcribes spoken commands to text in real-time using Whisper.

## Text-to-Speech

- Responds to commands with Piper TTS (male/female voices).
=======
- Listens continuously for the "Hey Buddy" wake word.
- Uses the Vosk speech recognition engine for offline, real-time detection.

## Speech-to-Text

- Transcribes spoken commands to text in real-time.
- Uses the Vosk model for accurate transcription.
>>>>>>> ac4a8ca8912caa3cd43886f11d33ff5aee34d24c

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
# Buddy Voice Service Spec

This spec defines the design and behavior of the Buddy Voice service.

## Wake Word Detection

- Uses YOLO VAD for voice activity detection.
- Listens continuously for voice commands.

## Speech-to-Text

- Transcribes spoken commands to text in real-time using Whisper.

## Text-to-Speech

- Responds to commands with Piper TTS (male/female voices).

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
