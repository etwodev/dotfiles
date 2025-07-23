#!/bin/bash
dir=~/Pictures/Screenshots
mkdir -p "$dir"
filename="$(date +%Y-%m-%d_%H-%M-%S).png"
grim -g "$(slurp)" "$dir/$filename" && wl-copy < "$dir/$filename"
