import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import threading
import time

class BuddyDevConsole(Gtk.Window):
    def __init__(self):
        super().__init__(title="Buddy Dev Console")
        self.set_default_size(400, 300)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER_ALWAYS)

        # Set window to bottom-right corner
        self.connect("realize", self.on_realize)

        # Create a vertical box
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)

        # Command execution log area
        self.log_view = Gtk.TextView()
        self.log_view.set_editable(False)
        self.log_view.set_wrap_mode(Gtk.WrapMode.WORD)
        scrolled_window = Gtk.ScrolledWindow()
        scrolled_window.add(self.log_view)
        vbox.pack_start(scrolled_window, True, True, 0)

        # Control buttons
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        vbox.pack_start(hbox, False, False, 0)

        self.pause_button = Gtk.Button(label="Pause")
        self.pause_button.connect("clicked", self.on_pause_button_clicked)
        hbox.pack_start(self.pause_button, True, True, 0)

        self.cancel_button = Gtk.Button(label="Cancel")
        self.cancel_button.connect("clicked", self.on_cancel_button_clicked)
        hbox.pack_start(self.cancel_button, True, True, 0)

        self.modify_button = Gtk.Button(label="Modify")
        self.modify_button.connect("clicked", self.on_modify_button_clicked)
        hbox.pack_start(self.modify_button, True, True, 0)

        # Start a thread to simulate real-time updates
        self.update_thread = threading.Thread(target=self.simulate_updates)
        self.update_thread.daemon = True
        self.update_thread.start()

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

    def on_pause_button_clicked(self, button):
        self.add_log_entry("Pause button clicked")

    def on_cancel_button_clicked(self, button):
        self.add_log_entry("Cancel button clicked")

    def on_modify_button_clicked(self, button):
        self.add_log_entry("Modify button clicked")

    def add_log_entry(self, text):
        buffer = self.log_view.get_buffer()
        buffer.insert(buffer.get_end_iter(), text + "\n")
        # Scroll to bottom
        adjustment = self.log_view.get_vadjustment()
        adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size())

    def simulate_updates(self):
        # Simulate real-time command execution and GUI actions
        while True:
            time.sleep(1)
            self.add_log_entry(f"Executing command: ls -l at {time.strftime('%H:%M:%S')}")
            self.add_log_entry(f"Mouse moved to (100, 100) at {time.strftime('%H:%M:%S')}")
            self.add_log_entry(f"Window 'Terminal' focused at {time.strftime('%H:%M:%S')}")

if __name__ == "__main__":
    app = BuddyDevConsole()
    app.show_all()
    app.connect("destroy", Gtk.main_quit)
    Gtk.main()
