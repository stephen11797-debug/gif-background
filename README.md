# Animated GIF Background

An animated GIF wallpaper / background for Linux (X11 + MATE/GNOME).

## What it does

- **`animebg.sh`** — Sets an animated GIF as the desktop wallpaper on every
  connected monitor using `xwinwrap` + `mpv`.
- **`start-bg.sh`** — Launches the animated background and an optional
  compose-image overlay.
- **`gif-control.py`** — A small GTK3 tray-style control window to
  start/stop the background and manage related GIF programs.

## Requirements

```bash
sudo apt install python3-gi gir1.2-gtk-3.0 mpv xwinwrap x11-xserver-utils
```

## Usage

```bash
# Start the animated GIF background
animebg.sh start

# Stop it
animebg.sh stop

# Launch the control panel
python3 gif-control.py
```

## Autostart

Copy `anime-bg.desktop` to `~/.config/autostart/` to launch on login.
