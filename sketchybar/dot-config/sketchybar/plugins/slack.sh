#!/bin/bash

if [ "$SENDER" = "mouse.clicked" ]; then
  open -a Slack
  exit 0
fi

STATUS_LABEL=$(lsappinfo info -only StatusLabel "Slack" 2>/dev/null)

if [ -z "$STATUS_LABEL" ]; then
  sketchybar --set "$NAME" label="" icon.color=0xff565f89
  exit 0
fi

LABEL=""
ICON_COLOR="0xff9ece6a"

if [[ $STATUS_LABEL =~ \"label\"=\"([^\"]*)\" ]]; then
  LABEL="${BASH_REMATCH[1]}"

  if [ -z "$LABEL" ]; then
    ICON_COLOR="0xff9ece6a"
  elif [ "$LABEL" = "•" ]; then
    ICON_COLOR="0xffe0af68"
  elif [[ $LABEL =~ ^[0-9]+$ ]]; then
    ICON_COLOR="0xfff7768e"
  else
    exit 0
  fi
else
  sketchybar --set "$NAME" label="" icon.color=0xff565f89
  exit 0
fi

sketchybar --set "$NAME" label="$LABEL" icon.color="$ICON_COLOR"
