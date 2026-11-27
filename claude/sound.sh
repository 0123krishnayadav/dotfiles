#!/bin/bash
# sound.sh NAME: play /System/Library/Sounds/NAME.aiff for a Claude Code hook,
# but only when you're away: no sound while a terminal is the frontmost app.
front=$(lsappinfo info -only bundleid "$(lsappinfo front)" 2>/dev/null)
case "$front" in
*com.mitchellh.ghostty* | *com.apple.Terminal*) exit 0 ;;
esac
(afplay "/System/Library/Sounds/$1.aiff" >/dev/null 2>&1 &)
