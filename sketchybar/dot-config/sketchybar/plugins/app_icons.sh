#!/bin/bash

APP_NAME="$1"

case "$APP_NAME" in
"Ghostty" | "Terminal" | "iTerm2" | "WezTerm" | "Alacritty")
  ICON="" ;;
"kitty")
  ICON="󰄛" ;;
"Finder")
  ICON="󰀶" ;;
"Firefox")
  ICON="󰈹" ;;
"Google Chrome")
  ICON="󰊯" ;;
"Safari" | "Arc" | "Microsoft Edge" | "Brave Browser")
  ICON="󰖟" ;;
"Obsidian")
  ICON="󰎚" ;;
"Code" | "Visual Studio Code")
  ICON="󰨞" ;;
"IntelliJ IDEA"*)
  ICON="" ;;
"Xcode")
  ICON="󰀵" ;;
"Spotify" | "Music")
  ICON="󰝚" ;;
"Messages")
  ICON="󰍡" ;;
"Slack")
  ICON="󰒱" ;;
"Microsoft Teams"* | "Amazon Chime")
  ICON="󰊻" ;;
"Discord")
  ICON="󰙯" ;;
"Microsoft Outlook")
  ICON="󰇮" ;;
"Preview" | "Skim")
  ICON="󰈙" ;;
"Notes")
  ICON="󰎚" ;;
"System Preferences" | "System Settings")
  ICON="" ;;
"Activity Monitor")
  ICON="󰍛" ;;
"Calendar")
  ICON="" ;;
"zoom.us")
  ICON="󰍫" ;;
"Docker"*)
  ICON="󰡨" ;;
*)
  ICON="󰘔" ;;
esac

printf '%s' "$ICON"
