-- Ring Dock: Option+Space, or a tap or click on the trackpad with three fingers, shows everything
-- in the Dock in a ring around the pointer, in the Dock's order, with its badges and running dots.
-- Point toward an item (anywhere on the ring or inside it, the direction counts) and click, or
-- keep holding the keys or the click, point and let go. Return opens the item pointed at; Esc,
-- a click outside the ring or in its middle, or the same keys or fingers again close it.
-- Resting on an app with 2 or more windows lists their names outside the ring, next to it:
-- move out onto one and click (or let go) to bring that window to the front. Only windows on
-- the current desktop (and minimized ones) can be listed. A right click on an item opens its
-- menu in the Dock.
-- It reads the real Dock (needs Accessibility), so pin and unpin apps in the Dock as usual.

local M = {}

local MODS, KEY = { "alt" }, "space"
local FINGERS = 3 -- or a trackpad tap or click with this many fingers
local TAP, MOVE = 0.3, 0.05 -- a tap: fingers down and up within this many seconds, moving less (trackpad = 1)
local ICON = 44 -- icon size, points: the whole ring scales with it
local GAP = 14 -- space between icons around the ring
local BAND = 12 -- ring around the icons, inside and out
local DEAD = 24 -- the pointer this close to the centre points at nothing
local HOLD = 0.3 -- seconds: hotkey held longer than this, letting go opens the item
local WAIT = 0.08 -- seconds on an app before its window list shows
local ROW, LIST_W = 24, 300 -- window list: row height, widest

local THEMES = {
  Dark = {
    ring = { red = 0.12, green = 0.12, blue = 0.14, alpha = 0.88 },
    edge = { white = 1, alpha = 0.14 },
    hole = { white = 0, alpha = 0.28 },
    hover = { white = 1, alpha = 0.16 },
    glow = { red = 0.5, green = 0.45, blue = 1, alpha = 0.7 },
    shadow = { white = 0, alpha = 0.6 },
    pill = { white = 0.22, alpha = 0.97 },
    text = { white = 1 },
    dim = { white = 1, alpha = 0.5 },
    dot = { white = 1, alpha = 0.75 },
  },
  Light = {
    ring = { white = 0.97, alpha = 0.85 },
    edge = { white = 1, alpha = 0.8 },
    hole = { red = 0.92, green = 0.91, blue = 0.98, alpha = 0.7 },
    hover = { white = 1, alpha = 0.85 },
    glow = { red = 0.45, green = 0.4, blue = 1, alpha = 0.45 },
    shadow = { red = 0.4, green = 0.35, blue = 0.8, alpha = 0.35 },
    pill = { white = 1, alpha = 0.97 },
    text = { white = 0 },
    dim = { white = 0, alpha = 0.45 },
    dot = { white = 0, alpha = 0.55 },
  },
}
local BADGE = { red = 1, green = 0.23, blue = 0.19 }
local BOLD = hs.styledtext.defaultFonts.boldSystem.name
local REGULAR = hs.styledtext.defaultFonts.system.name
local CENTRED = { alignment = "center", lineBreak = "wordWrap" }
local LEFT = { alignment = "left", lineBreak = "truncateTail" }
local ICONS = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/"

M.ring = nil -- the open ring, or nil

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function box(x, y, size) return { x = x - size / 2, y = y - size / 2, w = size, h = size } end

local function text(str, size, color, font, style)
  return hs.styledtext.new(str, { font = { name = font, size = size }, color = color, paragraphStyle = style or CENTRED })
end

local function path(url)
  if type(url) == "table" then url = url.url end
  if type(url) == "string" and url:match("^file://") then return hs.http.urlParts(url).path end
end

-- The Bin, full or empty. Listing it needs Full Disk Access, but a folder's link count is its
-- number of entries + 2 (on APFS), and .DS_Store doesn't count.
local function trashIcon()
  local trash = os.getenv("HOME") .. "/.Trash"
  local a = hs.fs.attributes(trash)
  local n = (a and a.nlink - 2 or 0) - (hs.fs.attributes(trash .. "/.DS_Store") and 1 or 0)
  return hs.image.imageFromPath(ICONS .. (n > 0 and "FullTrashIcon.icns" or "TrashIcon.icns"))
end

-- The Dock's items, as the Dock shows them (separators and minimized windows left out)
function M.items()
  local dock = hs.application.get("com.apple.dock")
  local list
  for _, el in ipairs(dock and hs.axuielement.applicationElement(dock):attributeValue("AXChildren") or {}) do
    if el:attributeValue("AXRole") == "AXList" then list = el end
  end
  local items = {}
  for _, el in ipairs(list and list:attributeValue("AXChildren") or {}) do
    local kind = el:attributeValue("AXSubrole")
    if kind ~= "AXSeparatorDockItem" and kind ~= "AXMinimizedWindowDockItem" then
      local file = path(el:attributeValue("AXURL"))
      local icon = kind == "AXTrashDockItem" and trashIcon() or file and hs.image.iconForFile(file)
      items[#items + 1] = {
        el = el,
        kind = kind,
        path = file,
        title = el:attributeValue("AXTitle") or "",
        running = el:attributeValue("AXIsApplicationRunning"),
        badge = el:attributeValue("AXStatusLabel"),
        icon = icon or hs.image.iconForFileType("public.data"),
      }
    end
  end
  return items
end

-- A running app's windows on the current desktop, minimized ones too (not Finder's desktop).
-- Not hs.application.get: for an ID that isn't running (an app whose windows belong to another
-- app, like Herdr's, or one quitting) it searches every window of every app, ~1.5 s stuck.
local function windows(it)
  local info = it.kind == "AXApplicationDockItem" and it.path and hs.application.infoForBundlePath(it.path)
  local app = info and info.CFBundleIdentifier and hs.application.applicationsForBundleID(info.CFBundleIdentifier)[1]
  local wins = {}
  for _, w in ipairs(app and app:allWindows() or {}) do
    if w:isStandard() then wins[#wins + 1] = w end
  end
  return wins
end

local function hideList(r)
  if r.wait then r.wait:stop() end
  if r.list then r.list.cv:delete() end
  r.wait, r.list, r.row = nil, nil, nil
end

-- The app's window names in a box just outside the ring, in the app's direction
local function showList(r, it)
  local wins = windows(it)
  if #wins < 2 then return end
  local t, labels, widest = r.theme, {}, 0
  for k, w in ipairs(wins) do
    local title = w:title() ~= "" and w:title() or it.title
    labels[k] = text(w:isMinimized() and title .. " (minimized)" or title, 12, w:isMinimized() and t.dim or t.text,
      REGULAR, LEFT)
    widest = math.max(widest, r.cv:minimumTextSize(labels[k]).w)
  end
  local pad = 6
  local w, h = math.min(widest, LIST_W) + 24, #wins * ROW + 2 * pad
  -- In the app's direction, growing away from the ring (right of an app on the right, above
  -- one at the top, ...), pushed out until its nearest point is 10 pt off the ring; on screen
  local cos, sin, gap = math.cos(it.a), math.sin(it.a), r.outer + 10
  local x, y
  for d = gap, gap + 200, 2 do
    x, y = r.cx + d * cos - (1 - cos) / 2 * w, r.cy + d * sin - (1 - sin) / 2 * h
    local nx, ny = clamp(r.cx, x, x + w) - r.cx, clamp(r.cy, y, y + h) - r.cy
    if nx * nx + ny * ny >= gap * gap then break end
  end
  x = clamp(x, r.screen.x + 4, r.screen.x + r.screen.w - w - 4)
  y = clamp(y, r.screen.y + 4, r.screen.y + r.screen.h - h - 4)

  local cv = hs.canvas.new({ x = x, y = y, w = w, h = h })
  cv:level(hs.canvas.windowLevels.popUpMenu)
  cv:behaviorAsLabels({ "canJoinAllSpaces", "fullScreenAuxiliary" })
  cv:appendElements({ type = "rectangle", frame = { x = 0.5, y = 0.5, w = w - 1, h = h - 1 }, fillColor = t.ring,
    strokeColor = t.edge, strokeWidth = 1, roundedRectRadii = { xRadius = 12, yRadius = 12 } })
  cv:appendElements({ type = "rectangle", frame = { x = 4, y = pad, w = w - 8, h = ROW }, fillColor = t.hover,
    action = "skip", roundedRectRadii = { xRadius = 7, yRadius = 7 } }) -- element 2: the row pointed at
  for k, label in ipairs(labels) do
    local th = cv:minimumTextSize(label).h
    cv:appendElements({ type = "text", text = label, frame = { x = 12, y = pad + (k - 1) * ROW + (ROW - th) / 2, w = w - 24, h = th } })
  end
  cv:show(0.08)
  r.list = { cv = cv, wins = wins, x = x, y = y, w = w, pad = pad }
end

-- The window row under the pointer, or nil
local function rowAt(l, p)
  local k = math.floor((p.y - l.y - l.pad) / ROW) + 1
  if p.x >= l.x and p.x <= l.x + l.w and k >= 1 and k <= #l.wins then return k end
end

local function setRow(r, k)
  if k == r.row then return end
  r.row = k
  r.list.cv:elementAttribute(2, "action", k and "fill" or "skip")
  if k then r.list.cv:elementAttribute(2, "frame", { x = 4, y = r.list.pad + (k - 1) * ROW, w = r.list.w - 8, h = ROW }) end
end

-- Highlight item i (nil: none), show its name in the middle, and soon its windows
local function highlight(i)
  local r = M.ring
  if i == r.sel then return end
  hideList(r)
  local cv, it = r.cv, r.items[r.sel]
  if it then cv:elementAttribute(it.img, "frame", box(it.x, it.y, r.icon)) end
  r.sel, it = i, r.items[i]
  for e, action in pairs({ [r.hover] = "strokeAndFill", [r.pill] = "fill", [r.label] = "strokeAndFill" }) do
    cv:elementAttribute(e, "action", it and action or "skip")
  end
  if not it then return end
  cv:elementAttribute(it.img, "frame", box(it.x, it.y, r.icon * 1.18))
  cv:elementAttribute(r.hover, "center", { x = it.x, y = it.y })
  local label = text(it.title, 13, r.theme.text, BOLD)
  local size, most = cv:minimumTextSize(label), r.inner * 2 - 16
  local w = math.min(size.w + 24, most)
  local h = size.h * (size.w + 24 > most and 2 or 1) -- a long name takes two lines
  cv:elementAttribute(r.pill, "frame", { x = r.c - w / 2, y = r.c - h / 2 - 6, w = w, h = h + 12 })
  cv:elementAttribute(r.label, "text", label)
  cv:elementAttribute(r.label, "frame", { x = r.c - w / 2 + 8, y = r.c - h / 2, w = w - 16, h = h })
  if it.running then
    r.wait = hs.timer.doAfter(WAIT, function()
      r.wait = nil
      if M.ring == r and r.sel == i then showList(r, it) end
    end)
  end
end

-- The item in the pointer's direction from the centre (none in the middle or outside the
-- ring), and whether the pointer is on the ring or inside it
local function pointed(p)
  local r = M.ring
  local dx, dy = p.x - r.cx, p.y - r.cy
  local d = math.sqrt(dx * dx + dy * dy)
  if d < DEAD or d > r.outer then return nil, d <= r.outer end
  local step = 2 * math.pi / #r.items
  return math.floor((math.atan(dy, dx) + math.pi / 2) / step + 0.5) % #r.items + 1, true
end

-- Follow the pointer. Off the ring, the app stays selected while its window list is showing
-- (or about to), so the pointer can move out to it
local function update()
  local r, p = M.ring, hs.mouse.absolutePosition()
  local i, inside = pointed(p)
  r.inside = inside
  if r.list then setRow(r, not inside and rowAt(r.list, p) or nil) end
  if inside or not (r.list or r.wait) then highlight(i) end
end

function M.close()
  local r = M.ring
  if not r then return end
  M.ring = nil
  r.tap:stop()
  hideList(r)
  r.cv:delete(0.12)
end

-- Bring the window pointed at to the front, or open the item the way a Dock click does
-- (folders open in Finder instead of a stack). Anywhere else: just close.
local function choose()
  local r = M.ring
  if not r then return end
  local win = r.row and r.list.wins[r.row]
  local it = r.inside and r.items[r.sel]
  M.close()
  if win then
    if win:isMinimized() then win:unminimize() end
    win:focus()
  elseif it then
    if it.kind == "AXFolderDockItem" and it.path then
      hs.open(it.path)
    elseif not it.el:performAction("AXPress") and it.path then
      hs.open(it.path)
    end
  end
end

-- Letting go of what opened the ring, after holding it and pointing: opens what's pointed at
local function letGo()
  local r = M.ring
  if r and (r.row or (r.inside and r.sel)) and hs.timer.secondsSinceEpoch() - r.opened > HOLD then choose() end
end

-- A right click on an item: its menu in the Dock, as if right-clicked there. Anywhere else: close.
local function dockMenu()
  local r = M.ring
  local it = r.inside and r.items[r.sel]
  M.close()
  if it then it.el:performAction("AXShowMenu") end
end

local E = hs.eventtap.event.types
local fingers = 0 -- on the trackpad now (not resting on it)
local function onEvent(e)
  if not M.ring then return false end -- closed, with events still queued for its tap
  local t = e:getType()
  if t == E.mouseMoved or t == E.leftMouseDragged or t == E.rightMouseDragged then
    update()
    return false
  elseif t == E.keyDown then
    local key = hs.keycodes.map[e:getKeyCode()]
    if key == "escape" then
      M.close()
    elseif key == "return" or key == "padenter" then
      choose()
    else
      return false
    end
    return true
  end
  -- Mouse buttons act on release; both halves of the click stay away from the app below
  local r = M.ring
  if t == r.held then -- letting go of the three-finger click that opened it
    r.held = nil
    letGo()
  elseif t == E.rightMouseDown then
    r.fingers = fingers -- FINGERS of them: the trackpad click that closes the ring, not a right click
  elseif t == E.leftMouseUp then
    choose()
  elseif t == E.rightMouseUp and r.fingers ~= FINGERS then
    dockMenu()
  elseif t == E.rightMouseUp or t == E.otherMouseUp then
    M.close()
  end
  return true
end

-- The trackpad: its touch events tell how many fingers are on it. A tap with FINGERS of them
-- (macOS sends no click for it) opens or closes the ring. A click with them opens it instead
-- of clicking: macOS mostly sends that as a right click (secondary click is on), sometimes as
-- a left one. Once the ring is open, its own tap gets the clicks first.
local touch -- since fingers went down: when, the most at once, where each started, moved, pressed
local UP = { [E.leftMouseDown] = E.leftMouseUp, [E.rightMouseDown] = E.rightMouseUp }

-- Hammerspoon sometimes stops getting finger data (seen after sleep): every gesture event comes
-- with no touches, so no tap is ever seen. Reload doesn't help, only a new process does: relaunch.
-- A press sends empty ones too (pressure), so only count them with no button down.
local STALE, empties = 150, 0 -- empty gesture events in a row
local function noTouches()
  if next(hs.eventtap.checkMouseButtons()) then empties = 0 return end
  empties = empties + 1
  if empties < STALE then return end
  empties = 0
  local last = hs.settings.get("ringDock.relaunched") or 0
  if os.time() - last < 600 then return end -- at most every 10 min, in case a relaunch doesn't help
  hs.settings.set("ringDock.relaunched", os.time())
  print("ring_dock: no finger data from the trackpad, relaunching Hammerspoon")
  hs.timer.doAfter(0, hs.relaunch)
end

local function onTrackpad(e)
  local t = e:getType()
  if t ~= E.gesture then
    if touch then touch.pressed = true end
    if fingers ~= FINGERS or M.ring then return false end
    M.open()
    if not M.ring then return false end -- no Accessibility: let the click through
    M.ring.held = UP[t] -- its release
    return true
  end
  local touches = e:getTouches() or {}
  if #touches == 0 then -- pressure changes: only a press sends them
    if touch then touch.pressed = true end
    noTouches()
    return false
  end
  empties = 0
  local s = touch or { start = hs.timer.secondsSinceEpoch(), most = 0, from = {} }
  fingers = 0
  for _, f in ipairs(touches) do
    if f.touching and not f.resting then fingers = fingers + 1 end
    local p, o = f.normalizedPosition, s.from[f.identity]
    if p and not o then
      s.from[f.identity] = p
    elseif p and math.abs(p.x - o.x) + math.abs(p.y - o.y) > MOVE then
      s.moved = true
    end
  end
  s.most = math.max(s.most, fingers)
  touch = fingers > 0 and s or nil
  if fingers == 0 and s.most == FINGERS and not (s.moved or s.pressed)
      and hs.timer.secondsSinceEpoch() - s.start < TAP then
    hs.timer.doAfter(0, function()
      if M.ring then M.close() else M.open() end
    end)
  end
  return false
end

function M.open()
  if not hs.accessibilityState(true) then
    hs.alert.show("Ring Dock needs Accessibility:\nSystem Settings → Privacy & Security → Accessibility → Hammerspoon", 5)
    return
  end
  local items = M.items()
  if #items == 0 then return end
  local scr = (hs.mouse.getCurrentScreen() or hs.screen.mainScreen()):frame()

  -- Ring size: icons spaced evenly; smaller icons if that doesn't fit the screen
  local n, icon = #items, ICON
  local radius = math.max(108, n * (icon + GAP) / (2 * math.pi)) -- at least: room for a name in the middle
  local most = math.min(scr.w, scr.h) / 2 - icon / 2 - BAND - 8
  if radius > most then
    radius = most
    icon = math.max(28, 2 * math.pi * radius / n - GAP)
  end
  local outer, inner = radius + icon / 2 + BAND, radius - icon / 2 - BAND

  -- Centred on the pointer, moved (pointer too) to fit on screen
  local m = hs.mouse.absolutePosition()
  local cx = clamp(m.x, scr.x + outer + 8, scr.x + scr.w - outer - 8)
  local cy = clamp(m.y, scr.y + outer + 8, scr.y + scr.h - outer - 8)
  if cx ~= m.x or cy ~= m.y then hs.mouse.absolutePosition({ x = cx, y = cy }) end

  local t = THEMES[hs.host.interfaceStyle() or "Light"] or THEMES.Light
  local c = outer + 50 -- canvas half-size: room for the shadow
  local cv = hs.canvas.new({ x = cx - c, y = cy - c, w = 2 * c, h = 2 * c })
  cv:level(hs.canvas.windowLevels.popUpMenu)
  cv:behaviorAsLabels({ "canJoinAllSpaces", "fullScreenAuxiliary" })
  local function add(e)
    cv:appendElements(e)
    return #cv
  end
  local centre = { x = c, y = c }
  add({ type = "circle", center = centre, radius = outer, fillColor = t.ring, strokeColor = t.edge, strokeWidth = 1,
    withShadow = true, shadow = { blurRadius = 40, color = t.shadow, offset = { h = -8, w = 0 } } })
  add({ type = "circle", center = centre, radius = inner, fillColor = t.hole, strokeColor = t.edge, strokeWidth = 1 })
  local hover = add({ type = "circle", center = centre, radius = icon * 0.78, fillColor = t.hover, strokeColor = t.edge,
    strokeWidth = 1, action = "skip", withShadow = true, shadow = { blurRadius = 24, color = t.glow, offset = { h = 0, w = 0 } } })

  for i, it in ipairs(items) do
    it.a = -math.pi / 2 + (i - 1) * 2 * math.pi / n -- clockwise from the top
    it.x, it.y = c + radius * math.cos(it.a), c + radius * math.sin(it.a)
    if it.running then
      local d = radius - icon / 2 - 7
      add({ type = "circle", center = { x = c + d * math.cos(it.a), y = c + d * math.sin(it.a) }, radius = 2.5,
        fillColor = t.dot, action = "fill" })
    end
    it.img = add({ type = "image", image = it.icon, frame = box(it.x, it.y, icon), imageScaling = "scaleProportionally" })
    if it.badge and it.badge ~= "" then
      local label = text(it.badge, 12, { white = 1 }, BOLD)
      local size = cv:minimumTextSize(label)
      local w, h = math.max(20, size.w + 10), 20
      local bx, by = it.x + icon / 2 - 6, it.y - icon / 2 + 4
      add({ type = "rectangle", frame = { x = bx - w / 2, y = by - h / 2, w = w, h = h }, fillColor = BADGE,
        roundedRectRadii = { xRadius = h / 2, yRadius = h / 2 }, strokeColor = { white = 1, alpha = 0.9 }, strokeWidth = 1.5 })
      add({ type = "text", text = label, frame = { x = bx - w / 2, y = by - size.h / 2, w = w, h = size.h } })
    end
  end

  local pill = add({ type = "rectangle", frame = box(c, c, 1), fillColor = t.pill, action = "skip",
    roundedRectRadii = { xRadius = 14, yRadius = 14 }, withShadow = true,
    shadow = { blurRadius = 10, color = { white = 0, alpha = 0.25 }, offset = { h = -2, w = 0 } } })
  local label = add({ type = "text", text = "", frame = box(c, c, 1), action = "skip" })

  M.ring = { cv = cv, items = items, theme = t, icon = icon, inner = inner, outer = outer, c = c, cx = cx, cy = cy,
    screen = scr, hover = hover, pill = pill, label = label, opened = hs.timer.secondsSinceEpoch() }
  M.ring.tap = hs.eventtap.new({ E.mouseMoved, E.leftMouseDragged, E.rightMouseDragged, E.leftMouseDown, E.leftMouseUp,
    E.rightMouseDown, E.rightMouseUp, E.otherMouseDown, E.otherMouseUp, E.keyDown }, onEvent):start()
  update()
  cv:show(0.1)
end

function M.start()
  -- Load these now, or the first Option+Space waits ~200 ms for them
  for _, ext in ipairs({ "axuielement", "http", "image", "canvas", "mouse", "screen", "host", "alert", "window" }) do
    local _ = hs[ext]
  end
  hs.timer.doAfter(1, M.items) -- and the first Dock read, which takes ~100 ms
  -- A busy or hung app answers Accessibility late or never: wait 0.25 s for it, not macOS's 6
  -- (all of Hammerspoon; the Dock answers in ms)
  hs.window.timeout(0.25)
  M.hotkey = hs.hotkey.bind(MODS, KEY, function()
    if M.ring then M.close() else M.open() end
  end, letGo)

  M.trackpad = hs.eventtap.new({ E.gesture, E.leftMouseDown, E.rightMouseDown }, onTrackpad):start()
end

return M
