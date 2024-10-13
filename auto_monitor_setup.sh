#!/bin/bash

# Function to get the primary monitor or the first connected monitor if no primary is set
get_primary_monitor() {
    primary=$(xrandr | grep " connected primary" | cut -d " " -f1)
    if [ -z "$primary" ]; then
        primary=$(xrandr | grep " connected" | head -n1 | cut -d " " -f1)
    fi
    echo "$primary"
}

# Function to get connected external monitors
get_connected_monitors() {
    primary=$(get_primary_monitor)
    xrandr | grep " connected" | grep -v "$primary" | cut -d " " -f1
}

# Function to get the best mode for a monitor
get_best_mode() {
    xrandr | awk -v monitor="$1" '$0 ~ monitor {flag=1; next} /connected/ {flag=0} flag {print $1; exit}'
}

# Function to set up monitors
setup_monitors() {
    local primary_monitor=$1
    local ext_monitor=$2
    local ext_mode=$3

    # Get the best mode for the primary monitor
    local primary_mode=$(get_best_mode "$primary_monitor")

    # Set up the primary monitor
    xrandr --output "$primary_monitor" --primary --mode "$primary_mode" --pos 0x0 --rotate normal

    if [ -n "$ext_monitor" ]; then
        # Set up the external monitor to the right of the primary monitor
        xrandr --output "$ext_monitor" --mode "$ext_mode" --right-of "$primary_monitor" --rotate normal
    fi

    # Turn off all other outputs
    for output in $(xrandr | grep " connected" | cut -d " " -f1 | grep -vE "$primary_monitor|$ext_monitor"); do
        xrandr --output "$output" --off
    done
}

# Main script
echo "Detecting monitors..."

# Get the primary monitor
primary_monitor=$(get_primary_monitor)
echo "Primary monitor detected: $primary_monitor"

# Get connected external monitor(s)
connected_monitors=$(get_connected_monitors)

if [ -z "$connected_monitors" ]; then
    echo "No external monitor detected. Using primary screen only."
    setup_monitors "$primary_monitor"
else
    # If multiple monitors are connected, use the first one
    ext_monitor=$(echo "$connected_monitors" | head -n1)
    echo "External monitor detected: $ext_monitor"
    best_mode=$(get_best_mode "$ext_monitor")
    echo "Best mode for $ext_monitor: $best_mode"
    setup_monitors "$primary_monitor" "$ext_monitor" "$best_mode"
    echo "Set up primary screen ($primary_monitor) and $ext_monitor in mode $best_mode"
fi

echo "Monitor configuration applied."
