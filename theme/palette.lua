-- "Dark 2026", VS Code's default dark theme: every color the repo's tools use, each named once.
-- Taken from VS Code's own theme files (2026-dark.json on top of Dark Modern and Dark+, in the app
-- under extensions/theme-defaults/themes), resolved the way VS Code resolves them.
--
-- Neovim reads this file (nvim/colors/dark2026.lua and its status line). build.lua writes
-- lazygit's, delta's and bat's theme files from it, so after changing a color run:
--   nvim -l ~/.config/theme/build.lua
--
-- #RRGGBBAA colors are see-through, as VS Code writes them. Tools without alpha paint them onto
-- a background with over(color, background); the background defaults to the editor's.
local p = {}

-- Backgrounds
p.bg = "#121314" -- editor
p.panel = "#191A1B" -- side bar, panels, status bar
p.widget = "#202122" -- popups: completion, hover, pickers
p.line = "#242526" -- current line; raised parts of the status bar
p.border = "#2A2B2C" -- lines between areas
p.input_border = "#333536" -- around inputs

-- Text
p.fg = "#BBBEBF" -- code
p.ui = "#bfbfbf" -- everything outside the editor
p.dim = "#8C8C8C" -- muted: hints, folder paths, inactive titles, gitignored files
p.line_nr = "#858889"
p.on_button = "#FFFFFF"

-- Accents
p.blue = "#48A0C7" -- links, matches, folders
p.focus = "#3994BC" -- focused borders and tabs
p.button = "#297AA0" -- buttons, the current search match
p.red = "#f48771" -- errors, deleted files
p.yellow = "#e5ba7d" -- warnings, modified files
p.green = "#73c991" -- added files

-- Selections and highlights (see-through)
p.selection = "#276782dd" -- selected text
p.search = "#27678280" -- search matches
p.word = "#27678250" -- other places the word under the cursor is used
p.word_write = "#27678280" -- ... and where it's written
p.quickfix = "#27678260" -- current item in a list of places
p.fold = "#2767824D" -- folded lines
p.bracket = "#3994BC55" -- the matching bracket
p.list_selection = "#FFFFFF22" -- selected item in a list
p.list_selection_inactive = "#2C2D2E" -- ... in a list that doesn't have focus
p.menu_selection = "#FFFFFF26" -- selected item in the completion menu
p.scrollbar = "#A8A9AA85"
p.whitespace = "#8C8C8C4D" -- tab and trailing-space markers
p.indent = "#8384854D" -- indent guides
p.indent_active = "#838485" -- ... of the current block
p.ghost_text = "#FFFFFF56" -- completion preview after the cursor
p.unnecessary = "#BBBEBFAA" -- unused code
p.inlay_hint = "#969696" -- type hints the language server adds to the code
p.inlay_hint_bg = "#6161611A"

-- Diagnostics and spelling
p.error = "#F14C4C"
p.warning = "#CCA700"
p.info = "#3794FF"

-- Git: changed lines in the gutter, and diffs
p.gutter = { add = "#72C892", change = "#0078D4", delete = "#F28772" }
p.diff = { add = "#347d3926", add_text = "#57ab5a4d", delete = "#c93c3726", delete_text = "#f470674d" }

-- Code, named after what they color in VS Code
p.syntax = {
  comment = "#8b949e",
  string = "#a5d6ff",
  escape = "#d7ba7d", -- also CSS selectors
  number = "#b5cea8",
  literal = "#569cd6", -- true, null, `new`, `typeof`, `static`, `async`, macros
  constant = "#79c0ff",
  variable = "#c9d1d9",
  parameter = "#ffa657",
  func = "#d2a8ff",
  builtin = "#DCDCAA", -- library functions: print, parseInt
  type = "#4EC9B0",
  keyword = "#ff7b72", -- const, function, class
  control = "#C586C0", -- if, return, import, await
  operator = "#d4d4d4",
  tag = "#7ee787", -- HTML tags, JSON and YAML keys
  attribute = "#9cdcfe",
  label = "#C8C8C8",
  tag_delimiter = "#808080", -- < > around HTML tags
  deleted = "#ffa198", -- removed lines in a diff, invalid code
  invalid = "#f44747",
  value = "#ce9178", -- CSS values (Dark+'s string color)
  regex_class = "#d16969",
  regex_constant = "#646695",
  quote_mark = "#6a9955", -- > before a Markdown quote
  header = "#000080",
  markup_ignored = "#0d1117",
  carriage_return = "#f0f6fc",
  log_info = "#6796e6",
  log_warn = "#cd9731",
  log_debug = "#b267e6",
}

-- File icons (VS Code's chart colors)
p.icons = {
  azure = "#57A3F8",
  green = "#86CF86",
  orange = "#CD861A",
  purple = "#AD80D7",
  red = "#EF8773",
  yellow = "#E0B97F",
}

-- Terminal colors: black, red, green, yellow, blue, magenta, cyan, white, then the bright ones
p.ansi = {
  "#000000",
  "#cd3131",
  "#0dbc79",
  "#e5e510",
  "#2472c8",
  "#bc3fbc",
  "#11a8cd",
  "#e5e5e5",
  "#666666",
  "#f14c4c",
  "#23d18b",
  "#f5f543",
  "#3b8eea",
  "#d670d6",
  "#29b8db",
  "#e5e5e5",
}

-- A see-through #RRGGBBAA color painted onto `base` (default: the editor background), as #RRGGBB
function p.over(color, base)
  base = base or p.bg
  local alpha = tonumber(color:sub(8, 9), 16) / 255
  local out = "#"
  for i = 2, 6, 2 do
    local c, b = tonumber(color:sub(i, i + 1), 16), tonumber(base:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(c * alpha + b * (1 - alpha) + 0.5))
  end
  return out
end

return p
