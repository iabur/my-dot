#!/bin/bash

# Function to get connected external monitors
get_connected_monitors() {
    xrandr | grep " connected" | grep -v "eDP-1" | cut -d " " -f1
}

# Function to get the best mode for a monitor
get_best_mode() {
    xrandr | awk -v monitor="$1" '$0 ~ monitor {flag=1; next} /connected/ {flag=0} flag {print $1; exit}'
}

# Function to set up monitors
setup_monitors() {
    local ext_monitor=$1
    local ext_mode=$2

    # Always set up eDP-1 as primary
    xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal

    if [ -n "$ext_monitor" ]; then
        # Set up the external monitor to the right of eDP-1
        xrandr --output "$ext_monitor" --mode "$ext_mode" --right-of eDP-1 --rotate normal
    fi

    # Turn off all other outputs
    for output in $(xrandr | grep " connected" | cut -d " " -f1 | grep -vE "eDP-1|$ext_monitor"); do
        xrandr --output "$output" --off
    done
}

# Main script
echo "Detecting monitors..."

# Get connected external monitor(s)
connected_monitors=$(get_connected_monitors)

if [ -z "$connected_monitors" ]; then
    echo "No external monitor detected. Using laptop screen only."
    setup_monitors
else
    # If multiple monitors are connected, use the first one
    ext_monitor=$(echo "$connected_monitors" | head -n1)
    echo "External monitor detected: $ext_monitor"

    best_mode=$(get_best_mode "$ext_monitor")
    echo "Best mode for $ext_monitor: $best_mode"

    setup_monitors "$ext_monitor" "$best_mode"
    echo "Set up laptop screen (eDP-1) and $ext_monitor in mode $best_mode"
fi

echo "Monitor configuration applied."
