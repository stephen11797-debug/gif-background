#!/bin/bash
# Animated GIF background - full screen on every connected monitor
# Usage: animebg.sh start [gif_path]   # start with the given or default GIF
#        animebg.sh stop               # stop the background
# Set a default GIF via LOCK_GIF env var.

stop() {
    pkill -f "xwinwrap.*-fdt" 2>/dev/null
    pkill -f "mpv.*\.gif" 2>/dev/null
}

case "${1:-start}" in
    stop)
        stop
        exit 0
        ;;
esac

GIF="${1:-${LOCK_GIF:-$HOME/Videos/linux back grounds /preview.gif}}"
[ -f "$GIF" ] || GIF="$HOME/Pictures/background.gif"

stop
sleep 1

# Parse each connected monitor: "NAME ... WxH+X+Y"
xrandr | grep " connected" | sed -n 's/.*connected[^0-9]*\([0-9]*\)x\([0-9]*\)+\([0-9]*\)+\([0-9]*\).*/\1 \2 \3 \4/p' | while read W H X Y; do
    setsid "$HOME/.local/bin/xwinwrap" -ni -o 1.0 -fdt -b -un \
        -g "${W}x${H}+${X}+${Y}" \
        -- mpv --wid=%WID --loop --no-audio --no-osc --no-input-default-bindings \
        --panscan=1.0 --really-quiet "$GIF" >/dev/null 2>&1 &
done
