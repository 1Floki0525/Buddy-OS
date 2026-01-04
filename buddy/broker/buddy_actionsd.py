import Xlib
import Xlib.display
from PIL import Image
import subprocess
import os

class BuddyActions:
    def __init__(self):
        self.display = Xlib.display.Display()
        self.root = self.display.screen().root

    def screen_capture(self):
        # Capture full screen
        width = self.display.screen().width_in_pixels
        height = self.display.screen().height_in_pixels
        raw_image = self.root.get_image(0, 0, width, height, Xlib.X.ZPixmap, 0xffffffff)
        image = Image.frombytes("RGB", (width, height), raw_image.data, "raw", "BGRX")
        return image

    def mouse_move(self, x, y):
        self.root.warp_pointer(x, y)
        self.display.sync()

    def mouse_click(self, button=1):
        # Button 1 = left, 3 = right
        self.root.send_event(Xlib.X.ButtonPress, button=button)
        self.root.send_event(Xlib.X.ButtonRelease, button=button)
        self.display.sync()

    def keyboard_type(self, text):
        # Use xdotool for typing
        subprocess.run(["xdotool", "type", text])

    def keyboard_press(self, key):
        # Use xdotool for key press
        subprocess.run(["xdotool", "key", key])

    def window_find(self, title):
        # Find windows by title
        windows = self.root.query_tree().children
        for window in windows:
            try:
                name = window.get_wm_name()
                if name and title in name:
                    return window
            except:
                continue
        return None

    def window_focus(self, window_id):
        # Focus specific window
        window = self.display.create_resource_object('window', window_id)
        window.set_input_focus(Xlib.X.RevertToParent, Xlib.X.CurrentTime)
        self.display.sync()

    def window_screenshot(self, window_id):
        # Screenshot specific window
        window = self.display.create_resource_object('window', window_id)
        geometry = window.get_geometry()
        raw_image = window.get_image(0, 0, geometry.width, geometry.height, Xlib.X.ZPixmap, 0xffffffff)
        image = Image.frombytes("RGB", (geometry.width, geometry.height), raw_image.data, "raw", "BGRX")
        return image

    def app_launch(self, command):
        # Launch applications
        subprocess.Popen(command, shell=True)

    def app_close(self, app_name):
        # Close applications
        subprocess.run(["pkill", "-f", app_name])

    def system_command(self, cmd):
        # Execute system commands with full privileges
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout, result.stderr

if __name__ == "__main__":
    actions = BuddyActions()
    # Example usage
    print("Screen capture...")
    image = actions.screen_capture()
    image.save("screenshot.png")
    print("Mouse move to (100, 100)")
    actions.mouse_move(100, 100)
    print("Left click")
    actions.mouse_click(1)
    print("Type 'Hello World'")
    actions.keyboard_type("Hello World")
    print("Press 'Enter'")
    actions.keyboard_press("Return")
    print("Find window with title 'Terminal'")
    window = actions.window_find("Terminal")
    if window:
        print(f"Window found: {window.id}")
        print("Focus window")
        actions.window_focus(window.id)
        print("Screenshot window")
        image = actions.window_screenshot(window.id)
        image.save("window_screenshot.png")
    print("Launch 'gedit'")
    actions.app_launch("gedit")
    print("Close 'gedit'")
    actions.app_close("gedit")
    print("Run system command 'ls -l'")
    stdout, stderr = actions.system_command("ls -l")
    print(f"stdout: {stdout}")
    print(f"stderr: {stderr}")
