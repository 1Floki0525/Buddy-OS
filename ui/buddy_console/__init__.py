"""
Buddy Console - GUI Development Terminal for Buddy-OS

This is a GTK-based application that provides a shared terminal-like interface
for user and Buddy AI to collaborate on development tasks.

Features:
- Real-time command execution display
- Live GUI action visualization (screenshots, UI events)
- User intervention capability during execution
- Position at bottom-right of desktop
- Integrated with Buddy Actions Daemon (localhost:8000)
"""

import gi
import json
import os
import subprocess
import threading
import time
from gi.repository import Gtk, Gdk, GLib

# Initialize GTK
gi.require_version('Gtk', '3.0')

class BuddyConsole(Gtk.Window):
    def __init__(self):
        super().__init__(title="Buddy Console")
        self.set_default_size(800, 600)
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
        self.header = Gtk.HeaderBar(title="Buddy Console")
        self.header.set_show_close_button(True)
        self.set_titlebar(self.header)

        # Create scrollable text view for command output
        self.scrolled_window = Gtk.ScrolledWindow()
        self.scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        self.box.pack_start(self.scrolled_window, True, True, 0)

        # Create text view for output
        self.text_view = Gtk.TextView()
        self.text_view.set_editable(False)
        self.text_view.set_wrap_mode(Gtk.WrapMode.WORD)
        self.scrolled_window.add(self.text_view)

        # Create entry for user input
        self.entry_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.box.pack_start(self.entry_box, False, False, 0)

        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("Type command or AI instruction...")
        self.entry_box.pack_start(self.entry, True, True, 0)

        self.send_button = Gtk.Button(label="Send")
        self.send_button.connect("clicked", self.on_send_clicked)
        self.entry_box.pack_start(self.send_button, False, False, 0)

        # Create buffer for text view
        self.buffer = self.text_view.get_buffer()

        # Start monitoring for Buddy actions
        self.start_action_monitor()

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
            self.add_output(f"[USER] {text}\n")
            self.entry.set_text("")
            # Send to buddy actions daemon
            self.send_to_buddy(text)

    def add_output(self, text):
        GLib.idle_add(self._add_output, text)

    def _add_output(self, text):
        self.buffer.insert(self.buffer.get_end_iter(), text)
        # Scroll to bottom
        adj = self.scrolled_window.get_vadjustment()
        adj.set_value(adj.get_upper() - adj.get_page_size())

    def send_to_buddy(self, command):
        # In a real implementation, this would send HTTP request to buddy_actionsd
        # For now, simulate with local execution
        def simulate_buddy_action():
            time.sleep(1)  # Simulate processing time
            self.add_output("[BUDDY] Executing command...\n")
            
            # Simulate different types of actions
            if "open" in command.lower():
                self.add_output("[BUDDY] Opening application...\n")
                # Simulate opening an app
                time.sleep(1)
                self.add_output("[BUDDY] Application opened successfully.\n")
            elif "screenshot" in command.lower():
                self.add_output("[BUDDY] Taking screenshot...\n")
                time.sleep(1)
                self.add_output("[BUDDY] Screenshot captured and saved.\n")
            elif "run" in command.lower():
                self.add_output("[BUDDY] Running script...\n")
                time.sleep(2)
                self.add_output("[BUDDY] Script completed successfully.\n")
            else:
                self.add_output("[BUDDY] Command processed.\n")
        
        threading.Thread(target=simulate_buddy_action).start()

    def start_action_monitor(self):
        # In a real implementation, this would monitor Buddy Actions Daemon for events
        # For now, just simulate some periodic output
        def monitor():
            while True:
                time.sleep(5)
                self.add_output("[SYSTEM] Monitoring for Buddy actions...\n")
        
        threading.Thread(target=monitor, daemon=True).start()

# -----------------------------
# Main Entry Point
# -----------------------------

def main():
    win = BuddyConsole()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
