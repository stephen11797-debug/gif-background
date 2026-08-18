#!/bin/bash
# Starts the animated GIF background.
# Usage: start-bg.sh [gif_path]
set -e

BIN_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$BIN_DIR/animebg.sh" start "${1:-}"
