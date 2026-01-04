import sys
import os
import sounddevice as sd
import numpy as np
<<<<<<< HEAD
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
=======
from vosk import Model, KaldiRecognizer, SetLogLevel
import json
import time

# Suppress Vosk logging
SetLogLevel(-1)

# Load Vosk model (download from https://alphacephei.com/vosk/models)
model = Model("model")

# Initialize recognizer with wake word ("Hey Buddy")
recognizer = KaldiRecognizer(model, 16000)
>>>>>>> ac4a8ca8912caa3cd43886f11d33ff5aee34d24c

# Audio stream callback
def audio_callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
<<<<<<< HEAD
    # Detect voice activity
    is_speech = vad.is_speech(indata.tobytes())
    if is_speech:
        # Transcribe speech to text using Whisper
        text = whisper_model.transcribe(indata.tobytes())
=======
    if recognizer.AcceptWaveform(indata.tobytes()):
        result = json.loads(recognizer.Result())
        text = result["text"].strip()
>>>>>>> ac4a8ca8912caa3cd43886f11d33ff5aee34d24c
        if text:
            print(f"Recognized: {text}")
            # Send to Buddy Copilot for execution
            execute_command(text)
<<<<<<< HEAD
            # Respond with Piper TTS
            respond_with_voice(text)
=======
>>>>>>> ac4a8ca8912caa3cd43886f11d33ff5aee34d24c

# Execute command via Buddy Copilot
def execute_command(command):
    # Placeholder for now — will be replaced with actual integration
    print(f"Executing command: {command}")

<<<<<<< HEAD
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
=======
# Start audio stream
with sd.InputStream(samplerate=16000, channels=1, dtype='int16', callback=audio_callback):
    print("Listening for 'Hey Buddy'...")
    while True:
        time.sleep(1)
model = Model("model")
>>>>>>> ac4a8ca8912caa3cd43886f11d33ff5aee34d24c
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
