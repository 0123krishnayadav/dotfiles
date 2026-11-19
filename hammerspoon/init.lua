-- Hammerspoon, linked to ~/.hammerspoon by setup.sh. After editing: menu bar icon → Reload Config.
require("hs.ipc") -- lets the `hs` command talk to the running app (setup.sh --check uses it)
hs.autoLaunch(true) -- open at login

ringDock = require("ring_dock") -- global, so it isn't garbage-collected
ringDock.start()
