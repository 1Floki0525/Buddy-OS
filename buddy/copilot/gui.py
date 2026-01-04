import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

class BuddyCopilot(Gtk.Window):
    def __init__(self):
        super().__init__(title="Buddy Copilot")
        self.set_default_size(300, 400)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER_ALWAYS)

        # Set window to bottom-right corner
        self.connect("realize", self.on_realize)

        # Create a vertical box
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)

        # Text input field
        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("Type a command...")
        self.entry.connect("activate", self.on_entry_activate)
        vbox.pack_start(self.entry, False, False, 0)

        # Voice activation button
        self.voice_button = Gtk.Button(label="Hey Buddy")
        self.voice_button.connect("clicked", self.on_voice_button_clicked)
        vbox.pack_start(self.voice_button, False, False, 0)

        # Scrollable log area
        self.log_view = Gtk.TextView()
        self.log_view.set_editable(False)
        self.log_view.set_wrap_mode(Gtk.WrapMode.WORD)
        scrolled_window = Gtk.ScrolledWindow()
        scrolled_window.add(self.log_view)
        vbox.pack_start(scrolled_window, True, True, 0)

    def on_realize(self, widget):
        # Position window in bottom-right corner
        screen = self.get_screen()
        monitor = screen.get_monitor_at_window(self.get_window())
        geometry = screen.get_monitor_geometry(monitor)
        width = self.get_allocated_width()
        height = self.get_allocated_height()
        x = geometry.width - width
        y = geometry.height - height
        self.move(x, y)

    def on_entry_activate(self, entry):
        command = entry.get_text()
        self.add_log_entry(f"Command: {command}")
        entry.set_text("")

    def on_voice_button_clicked(self, button):
        self.add_log_entry("Voice activation triggered: Hey Buddy")

    def add_log_entry(self, text):
        buffer = self.log_view.get_buffer()
        buffer.insert(buffer.get_end_iter(), text + "\n")
        # Scroll to bottom
        adjustment = self.log_view.get_vadjustment()
        adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size())

if __name__ == "__main__":
    app = BuddyCopilot()
    app.show_all()
    app.connect("destroy", Gtk.main_quit)
    Gtk.main()
import requests
import json

class BuddyCopilot(Gtk.Window):
    def __init__(self):
        super().__init__(title="Buddy Copilot")
        self.set_default_size(300, 400)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER_ALWAYS)

        # Set window to bottom-right corner
        self.connect("realize", self.on_realize)

        # Create a vertical box
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)

        # Text input field
        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("Type a command...")
        self.entry.connect("activate", self.on_entry_activate)
        vbox.pack_start(self.entry, False, False, 0)

        # Voice activation button
        self.voice_button = Gtk.Button(label="Hey Buddy")
        self.voice_button.connect("clicked", self.on_voice_button_clicked)
        vbox.pack_start(self.voice_button, False, False, 0)

        # Scrollable log area
        self.log_view = Gtk.TextView()
        self.log_view.set_editable(False)
        self.log_view.set_wrap_mode(Gtk.WrapMode.WORD)
        scrolled_window = Gtk.ScrolledWindow()
        scrolled_window.add(self.log_view)
        vbox.pack_start(scrolled_window, True, True, 0)

    def on_realize(self, widget):
        # Position window in bottom-right corner
        screen = self.get_screen()
        monitor = screen.get_monitor_at_window(self.get_window())
        geometry = screen.get_monitor_geometry(monitor)
        width = self.get_allocated_width()
        height = self.get_allocated_height()
        x = geometry.width - width
        y = geometry.height - height
        self.move(x, y)

    def on_entry_activate(self, entry):
        command = entry.get_text()
        self.add_log_entry(f"Command: {command}")
        # Send command to broker API
        self.send_command_to_broker(command)
        entry.set_text("")

    def on_voice_button_clicked(self, button):
        self.add_log_entry("Voice activation triggered: Hey Buddy")

    def add_log_entry(self, text):
        buffer = self.log_view.get_buffer()
        buffer.insert(buffer.get_end_iter(), text + "\n")
        # Scroll to bottom
        adjustment = self.log_view.get_vadjustment()
        adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size())

    def send_command_to_broker(self, command):
        # Send command to broker API
        url = "http://127.0.0.1:8765/execute"
        payload = {
            "action": "shell",
            "params": {
                "cmd": command
            },
            "consent": False,
            "reason": "User input via Buddy Copilot"
        }
        try:
            response = requests.post(url, json=payload)
            if response.status_code == 200:
                result = response.json()
                if result["ok"]:
                    self.add_log_entry(f"Success: {result['result']}")
                else:
                    self.add_log_entry(f"Error: {result['error']}")
            else:
                self.add_log_entry(f"Broker API error: {response.status_code}")
        except Exception as e:
            self.add_log_entry(f"Error sending command: {e}")

if __name__ == "__main__":
    app = BuddyCopilot()
    app.show_all()
    app.connect("destroy", Gtk.main_quit)
    Gtk.main()
