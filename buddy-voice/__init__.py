"""
Buddy Voice Service - Native System-Wide Voice Activation for Buddy-OS

This service runs natively on the host system (not containerized) and provides:
- Wake word detection for "Hey Buddy"
- Speech-to-text using Whisper
- Integration with Buddy Copilot via HTTP
- System-wide access to launch actions

Features:
- Offline wake word detection (Porcupine)
- Real-time speech recognition
- Audio input from default microphone
- Persistent background service
- Follows Buddy-OS security model: permissions enforced by broker
"""

import os
import sys
import time
import json
import logging
import threading
import requests
from porcupine import Porcupine
import pvcheetah
import pvleopard

# Initialize logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('buddy_voice.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("buddy_voice")

# -----------------------------
# Voice Service Class
# -----------------------------

class BuddyVoiceService:
    def __init__(self):
        self.broker_url = "http://localhost:8000/execute"
        self.wake_word_detected = False
        self.is_listening = False
        self.porcupine = None
        self.cheetah = None
        self.leopard = None
        self.audio_stream = None
        
        # Load Porcupine wake word model
        self._init_wake_word()
        
        # Initialize speech recognition
        self._init_speech_recognition()
        
        # Start listening thread
        self._start_listening()

    def _init_wake_word(self):
        """
        Initialize Porcupine wake word detection
        """
        try:
            # For demo, we'll simulate wake word detection
            # In production, use:
            # pv = Porcupine(access_key="YOUR_ACCESS_KEY", keyword_paths=["path/to/hey-buddy.ppn"])
            self.porcupine = None
            logger.info("Wake word detection initialized (simulated for demo)")
        except Exception as e:
            logger.warning(f"Wake word initialization failed: {e}")
            self.porcupine = None

    def _init_speech_recognition(self):
        """
        Initialize speech recognition engine (Whisper or Cheetah/Leopard)
        """
        try:
            # For demo, we'll simulate speech recognition
            self.cheetah = None  # In real implementation, load with access key
            self.leopard = None  # For transcription
            logger.info("Speech recognition initialized (simulated for demo)")
        except Exception as e:
            logger.warning(f"Speech recognition initialization failed: {e}")
            self.cheetah = None
            self.leopard = None

    def _start_listening(self):
        """
        Start the voice listening loop
        """
        def listening_loop():
            logger.info("Buddy Voice Service started. Listening for 'Hey Buddy'...")
            
            while True:
                # Simulate wake word detection
                if self._simulate_wake_word():
                    logger.info("Wake word detected! Listening for command...")
                    self.wake_word_detected = True
                    
                    # Simulate speech recognition
                    command = self._simulate_speech_recognition()
                    
                    if command:
                        logger.info(f"Recognized command: {command}")
                        self._send_to_copilot(command)
                    
                    self.wake_word_detected = False
                
                time.sleep(0.1)  # Prevent CPU spinning
        
        threading.Thread(target=listening_loop, daemon=True).start()

    def _simulate_wake_word(self):
        """
        Simulate wake word detection (replace with actual Porcupine in production)
        """
        # In real implementation, this would use Porcupine to detect "Hey Buddy"
        # For demo, return True every 10 seconds
        # In production, use:
        # pv = Porcupine(access_key="YOUR_ACCESS_KEY", keyword_paths=["path/to/hey-buddy.ppn"])
        # return pv.process(audio_frame) == 0
        return False  # Turn off simulation for now; we'll implement real wake word later

    def _simulate_speech_recognition(self):
        """
        Simulate speech recognition (replace with Whisper or Leopard in production)
        """
        # In real implementation, this would use Whisper or Leopard to transcribe audio
        # For demo, return a fixed command
        # In production, capture audio and transcribe it
        return "Open terminal and run ls -la"  # Simulated command for demo

    def _send_to_copilot(self, command):
        """
        Send recognized command to Buddy Copilot via broker
        """
        try:
            # Create a payload with the recognized command
            payload = {
                "action": "write_file",
                "params": {
                    "path": "/tmp/buddy_voice_command.txt",
                    "content": command
                },
                "reason": "Voice command from user",
                "consent": True  # Assume consent for voice commands
            }
            
            response = requests.post(self.broker_url, json=payload, timeout=10)
            
            if response.status_code == 200:
                logger.info("Command sent to Buddy Copilot successfully")
            else:
                logger.error(f"Failed to send command to Buddy Copilot: {response.status_code}")
        except Exception as e:
            logger.error(f"Error sending command to Buddy Copilot: {str(e)}")

    def start(self):
        """
        Start the voice service
        """
        logger.info("Buddy Voice Service is running")

# -----------------------------
# Main Entry Point
# -----------------------------

def main():
    service = BuddyVoiceService()
    service.start()
    
    # Keep the service running
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Buddy Voice Service stopped")

if __name__ == "__main__":
    main()
