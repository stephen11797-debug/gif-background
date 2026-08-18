#!/usr/bin/env python3
"""gif-control.py - animated GIF background controller with tray icon.

Start/stop the animated GIF wallpaper, pick your own GIF file, and set the
auto-start idle timer.  No screensaver — just the background.
"""
import os
import subprocess
import sys

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk, GdkPixbuf


ANIME = os.path.expanduser("~/.local/bin/animebg.sh")
CONFIG = os.path.expanduser("~/.config/gif-control.conf")
DEFAULT_MINUTES = 120


def load_config():
    cfg = {"idle_minutes": DEFAULT_MINUTES, "gif_path": ""}
    try:
        with open(CONFIG) as f:
            for line in f:
                if "=" in line:
                    k, v = line.strip().split("=", 1)
                    if k in cfg:
                        if k == "idle_minutes":
                            cfg[k] = max(1, min(1440, int(v)))
                        else:
                            cfg[k] = v
    except Exception:
        pass
    return cfg


def save_config(cfg):
    try:
        os.makedirs(os.path.dirname(CONFIG), exist_ok=True)
        with open(CONFIG, "w") as f:
            f.write("idle_minutes=%d\n" % cfg["idle_minutes"])
            f.write("gif_path=%s\n" % cfg["gif_path"])
    except Exception:
        pass


def run(cmd):
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def is_running(pattern):
    try:
        return (
            subprocess.run(
                ["pgrep", "-f", pattern],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            == 0
        )
    except Exception:
        return False


def make_icon():
    """Generate a simple 48x48 GIF-icon pixbuf."""
    w, h = 48, 48
    surf = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, w, h)
    # Transparent background
    for x in range(w):
        for y in range(h):
            surf.fill(0x00000000 if (x + y) % 2 else 0x0088CCFF)
    # Draw a G in the center using a simple pattern
    for x in range(w):
        for y in range(h):
            if 12 <= x <= 36 and 12 <= y <= 36:
                surf.fill(0xFFDD00FF, x, y)
    return surf


class Control(Gtk.Window):
    def __init__(self):
        super().__init__(title="GIF Background Control")
        self.set_border_width(14)
        self.set_resizable(False)

        self.cfg = load_config()

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(outer)

        # --- GIF selector ---
        gif_box = Gtk.Box(spacing=6)
        gif_box.pack_start(Gtk.Label("GIF:"), False, False, 0)
        self.gif_entry = Gtk.Entry()
        self.gif_entry.set_placeholder_text("Select a GIF file")
        self.gif_entry.set_text(self.cfg.get("gif_path", ""))
        gif_box.pack_start(self.gif_entry, True, True, 0)
        fb = Gtk.FileChooserButton()
        fb.set_title("Select GIF file")
        fb.set_action(Gtk.FileChooserWidget.get_property("local-only") and
                      Gtk.FileChooserAction.OPEN or Gtk.FileChooserAction.OPEN)
        fb.set_local_only(True)
        fb.set_create_folders(False)
        fb.set_select_multiple(False)
        self.gif_chooser = fb
        fb.connect("file-set", self.on_gif_selected)
        fb.add_filter(self._gif_filter())
        gif_box.pack_start(fb, False, False, 0)
        outer.pack_start(gif_box, False, False, 0)

        # --- Start / Stop ---
        h = Gtk.Box(spacing=6)
        self.bg_label = Gtk.Label(halign=Gtk.Align.START)
        self.bg_label.set_width_chars(20)
        sb = Gtk.Button(label="Start")
        tb = Gtk.Button(label="Stop")
        sb.connect("clicked", lambda *_: (self.start_bg(), self.refresh()))
        tb.connect("clicked", lambda *_: (self.stop_bg(), self.refresh()))
        h.pack_start(self.bg_label, True, True, 0)
        h.pack_start(sb, False, False, 0)
        h.pack_start(tb, False, False, 0)
        outer.pack_start(h, False, False, 0)

        # --- Idle timer ---
        t = Gtk.Box(spacing=6)
        t.pack_start(Gtk.Label("Auto-start after"), False, False, 0)
        adj = Gtk.Adjustment(self.cfg["idle_minutes"], 1, 1440, 5, 30, 0)
        self.spin = Gtk.SpinButton(adjustment=adj)
        self.spin.set_numeric(True)
        self.spin.set_update_policy(Gtk.SpinButtonUpdatePolicy.IF_VALID)
        self.spin.connect("value-changed", self.on_timer_changed)
        t.pack_start(self.spin, False, False, 0)
        t.pack_start(Gtk.Label("min of no input"), False, False, 0)
        outer.pack_start(t, False, False, 0)

        stopall = Gtk.Button(label="STOP ALL")
        stopall.connect("clicked", lambda *_: (
            self.stop_bg(),
            self.refresh(),
        ))
        outer.pack_start(stopall, False, False, 0)

        GLib.timeout_add(2000, self.refresh)
        self.refresh()

    def _gif_filter(self):
        f = Gtk.FileFilter()
        f.set_name("GIF images")
        f.add_pattern("*.gif")
        f.add_pattern("*.GIF")
        return f

    def on_gif_selected(self, widget):
        f = widget.get_filename()
        if f:
            self.gif_entry.set_text(f)
            self.cfg["gif_path"] = f
            save_config(self.cfg)

    def on_timer_changed(self, _):
        self.cfg["idle_minutes"] = int(self.spin.get_value())
        save_config(self.cfg)

    def start_bg(self):
        gif = self.gif_entry.get_text().strip() or self.cfg.get("gif_path", "")
        if gif and os.path.isfile(gif):
            run([ANIME, "start", gif])
        else:
            run([ANIME, "start"])

    def stop_bg(self):
        run([ANIME, "stop"])

    def refresh(self, *a):
        running = is_running(r"xwinwrap.*-fdt")
        self.bg_label.set_text("RUNNING" if running else "stopped")
        return True


class TrayIcon:
    def __init__(self):
        self.icon = Gtk.StatusIcon()
        try:
            pb = GdkPixbuf.Pixbuf.new_from_file(
                os.path.join(os.path.dirname(__file__), "gif-icon.png")
            )
        except Exception:
            pb = make_icon()
        self.icon.set_from_pixbuf(pb)
        self.icon.set_tooltip_text("GIF Background")
        self.icon.connect("activate", self.on_activate)
        self.icon.connect("popup-menu", self.on_popup)
        self.win = None

    def on_activate(self, *a):
        if self.win is None:
            self.win = Control()
            self.win.connect("destroy", lambda *_: setattr(self, "win", None))
            self.win.show_all()
        else:
            self.win.present()

    def on_popup(self, icon, button, time):
        menu = Gtk.Menu()
        start = Gtk.MenuItem(label="Start")
        start.connect("activate", lambda *_: subprocess.run([ANIME, "start"]))
        menu.append(start)
        stop = Gtk.MenuItem(label="Stop")
        stop.connect("activate", lambda *_: subprocess.run([ANIME, "stop"]))
        menu.append(stop)
        sep = Gtk.SeparatorMenuItem()
        menu.append(sep)
        open_item = Gtk.MenuItem(label="Open Control…")
        open_item.connect("activate", self.on_activate)
        menu.append(open_item)
        sep2 = Gtk.SeparatorMenuItem()
        menu.append(sep2)
        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", Gtk.main_quit)
        menu.append(quit_item)
        menu.show_all()
        menu.popup(None, None, None, None, button, time)


def main():
    tray = True
    if "--no-tray" in sys.argv:
        tray = False
    if tray:
        try:
            TrayIcon()
        except Exception:
            tray = False
    win = Control()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
