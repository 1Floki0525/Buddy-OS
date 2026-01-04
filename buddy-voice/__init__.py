import sys
import os
import sounddevice as sd
import numpy as np
import whisper
from vad import VAD
import piper
import time

# Load Whisper model
whisper_model = whisper.load_model("base")

# Initialize YOLO VAD
vad = VAD()

# Initialize Piper TTS (using pre-downloaded male/female voices)
piper_model_male = piper.load_model("piper-models/en_male.onnx")
piper_model_female = piper.load_model("piper-models/en_female.onnx")

# Audio stream callback
def audio_callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    # Detect voice activity
    is_speech = vad.is_speech(indata.tobytes())
    if is_speech:
        # Transcribe speech to text using Whisper
        text = whisper_model.transcribe(indata.tobytes())
        if text:
            print(f"Recognized: {text}")
            # Send to Buddy Copilot for execution
            execute_command(text)
            # Respond with Piper TTS
            respond_with_voice(text)

# Execute command via Buddy Copilot
def execute_command(command):
    # Placeholder for now — will be replaced with actual integration
    print(f"Executing command: {command}")

# Respond with Piper TTS
def respond_with_voice(text):
    # Use male voice by default
    audio = piper_model_male.synthesize(text)
    # Play audio
    sd.play(audio, samplerate=22050)
    sd.wait()

# Start audio stream
with sd.InputStream(samplerate=16000, channels=1, dtype='int16', callback=audio_callback):
    print("Listening for voice commands...")
    while True:
        time.sleep(1)
