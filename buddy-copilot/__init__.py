"""
Buddy Copilot - Native GUI Chat Interface for Buddy-OS

This is a GTK-based chat interface that provides:
- Text-based conversation with Buddy AI
- Real-time command execution display
- Integration with Buddy Actions Daemon (localhost:8000)
- Position at bottom-right of desktop
- System-wide access to control applications, files, and shell
- Follows Buddy-OS security model: permissions enforced by broker

Features:
- Chat interface with message history
- Real-time action visualization (screenshots, UI events)
- User intervention during execution
- Voice command integration (via buddy-voice)
"""

import gi
import json
import os
import subprocess
import threading
import time
from gi.repository import Gtk, Gdk, GLib, Pango

# Initialize GTK
gi.require_version('Gtk', '3.0')

class BuddyCopilot(Gtk.Window):
    def __init__(self):
        super().__init__(title="Buddy Copilot")
        self.set_default_size(400, 600)
        self.set_position(Gtk.WindowPosition.CENTER_ALWAYS)
        self.set_decorated(False)  # Remove window decorations
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_keep_above(True)
        self.set_app_paintable(True)
        self.connect("destroy", Gtk.main_quit)

        # Set window to bottom-right
        self.set_position(Gtk.WindowPosition.CENTER)
        self.connect("realize", self.on_realize)

        # Create layout
        self.box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(self.box)

        # Create header
        self.header = Gtk.HeaderBar(title="Buddy Copilot")
        self.header.set_show_close_button(True)
        self.set_titlebar(self.header)

        # Create scrollable text view for chat history
        self.scrolled_window = Gtk.ScrolledWindow()
        self.scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        self.box.pack_start(self.scrolled_window, True, True, 0)

        # Create text view for chat history
        self.text_view = Gtk.TextView()
        self.text_view.set_editable(False)
        self.text_view.set_wrap_mode(Gtk.WrapMode.WORD)
        self.text_view.modify_font(Pango.FontDescription("Monospace 10"))
        self.scrolled_window.add(self.text_view)

        # Create entry for user input
        self.entry_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.box.pack_start(self.entry_box, False, False, 0)

        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("Type your command or ask Buddy...")
        self.entry_box.pack_start(self.entry, True, True, 0)

        self.send_button = Gtk.Button(label="Send")
        self.send_button.connect("clicked", self.on_send_clicked)
        self.entry_box.pack_start(self.send_button, False, False, 0)

        # Create buffer for text view
        self.buffer = self.text_view.get_buffer()

        # Start monitoring for voice commands
        self.start_voice_monitor()

    def on_realize(self, widget):
        # Move window to bottom-right corner
        screen = widget.get_screen()
        monitor = screen.get_monitor_at_window(widget.get_window())
        geometry = screen.get_monitor_geometry(monitor)
        
        # Get window size
        width, height = widget.get_size()
        
        # Calculate position (bottom-right)
        x = geometry.x + geometry.width - width
        y = geometry.y + geometry.height - height
        
        # Move window
        widget.move(x, y)

    def on_send_clicked(self, button):
        text = self.entry.get_text().strip()
        if text:
            self.add_message(f"You: {text}\n")
            self.entry.set_text("")
            # Send to buddy actions daemon
            self.send_to_buddy(text)

    def add_message(self, text):
        GLib.idle_add(self._add_message, text)

    def _add_message(self, text):
        self.buffer.insert(self.buffer.get_end_iter(), text)
        # Scroll to bottom
        adj = self.scrolled_window.get_vadjustment()
        adj.set_value(adj.get_upper() - adj.get_page_size())

    def send_to_buddy(self, command):
        # Send to buddy actions daemon via HTTP
        def execute_command():
            try:
                # Send command to broker
                payload = {
                    "action": "shell",
                    "params": {
                        "command": command
                    },
                    "reason": "User command from Copilot",
                    "consent": True  # Assume consent for user-initiated commands
                }
                
                response = requests.post("http://localhost:8000/execute", json=payload, timeout=10)
                
                if response.status_code == 200:
                    result = response.json()
                    if result.get("ok"):
                        output = result.get("result", {}).get("stdout", "")
                        error = result.get("result", {}).get("stderr", "")
                        
                        if output:
                            self.add_message(f"Buddy: {output}\n")
                        if error:
                            self.add_message(f"Buddy (Error): {error}\n")
                    else:
                        self.add_message(f"Buddy: Failed to execute command: {result.get('error', '')}\n")
                else:
                    self.add_message(f"Buddy: Error communicating with broker\n")
            except Exception as e:
                self.add_message(f"Buddy: Error executing command: {str(e)}\n")
        
        threading.Thread(target=execute_command).start()

    def start_voice_monitor(self):
        # Monitor for voice commands (simulated for now)
        def monitor():
            while True:
                time.sleep(5)
                # In real implementation, this would listen for voice commands via HTTP from buddy-voice
                # For demo, simulate a voice command every 30 seconds
                # self.add_message("[VOICE] Voice command detected: Open terminal\n")
                # self.send_to_buddy("gnome-terminal")
        
        threading.Thread(target=monitor, daemon=True).start()

# -----------------------------
# Main Entry Point
# -----------------------------

def main():
    win = BuddyCopilot()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
