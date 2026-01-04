import sys
import os
import sounddevice as sd
import numpy as np
from vosk import Model, KaldiRecognizer, SetLogLevel
import json
import time

# Suppress Vosk logging
SetLogLevel(-1)

# Load Vosk model (download from https://alphacephei.com/vosk/models)
model = Model("model")

# Initialize recognizer with wake word ("Hey Buddy")
recognizer = KaldiRecognizer(model, 16000)

# Audio stream callback
def audio_callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    if recognizer.AcceptWaveform(indata.tobytes()):
        result = json.loads(recognizer.Result())
        text = result["text"].strip()
        if text:
            print(f"Recognized: {text}")
            # Send to Buddy Copilot for execution
            execute_command(text)

# Execute command via Buddy Copilot
def execute_command(command):
    # Placeholder for now — will be replaced with actual integration
    print(f"Executing command: {command}")

# Start audio stream
with sd.InputStream(samplerate=16000, channels=1, dtype='int16', callback=audio_callback):
    print("Listening for 'Hey Buddy'...")
    while True:
        time.sleep(1)
model = Model("model")
