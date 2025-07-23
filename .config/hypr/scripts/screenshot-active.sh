#!/bin/bash
dir=~/Pictures/Screenshots
mkdir -p "$dir"
filename="$(date +%Y-%m-%d_%H-%M-%S).png"
geometry=$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
grim -g "$geometry" "$dir/$filename" && wl-copy < "$dir/$filename"
