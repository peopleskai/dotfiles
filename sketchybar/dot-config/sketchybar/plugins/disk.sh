#!/bin/bash

USAGE=$(df -H /System/Volumes/Data 2>/dev/null | awk 'NR==2 {print $5}')
if [ -z "$USAGE" ]; then
  USAGE=$(df -H / | awk 'NR==2 {print $5}')
fi

sketchybar --set "$NAME" label="$USAGE"
