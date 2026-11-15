-- "Dark 2026", VS Code's default dark theme, for Neovim.
-- Every color is taken from VS Code's own theme files (2026-dark.json on top of Dark Modern and
-- Dark+, in the app under extensions/theme-defaults/themes), resolved the way VS Code resolves
-- them, so code looks the same in both editors. The status line is lua/lualine/themes/dark2026.lua.
vim.o.background = "dark"
vim.cmd("highlight clear")
vim.g.colors_name = "dark2026"

local bg, fg = "#121314", "#BBBEBF" -- editor.background, editor.foreground
local widget, panel, border = "#202122", "#191A1B", "#2A2B2C" -- popups, bars, lines between them
local ui, dim = "#bfbfbf", "#8C8C8C" -- text outside the editor, and its muted form

-- VS Code writes see-through colors as #RRGGBBAA. Neovim has no alpha, so paint them onto `base`.
local function over(color, base)
  base = base or bg
  local alpha = tonumber(color:sub(8, 9), 16) / 255
  local out = "#"
  for i = 2, 6, 2 do
    local c, b = tonumber(color:sub(i, i + 1), 16), tonumber(base:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(c * alpha + b * (1 - alpha) + 0.5))
  end
  return out
end

local selection = over("#276782dd")
local blue, red, yellow, green = "#48A0C7", "#f48771", "#e5ba7d", "#73c991" -- links, errors, warnings, added

-- Syntax colors, named after what they color in VS Code
local c = {
  comment = "#8b949e",
  string = "#a5d6ff",
  escape = "#d7ba7d",
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
}

-- Git changes in the sign column (editorGutter.*)
local signs = { Add = "#72C892", Change = "#0078D4", Delete = "#F28772" }

-- A string links to that group; {} clears a group so the highlight under it shows through
local groups = {
  -- Editor
  Normal = { fg = fg, bg = bg },
  NormalNC = "Normal",
  NormalFloat = { fg = ui, bg = widget },
  FloatBorder = { fg = border, bg = widget },
  FloatTitle = { fg = ui, bg = widget, bold = true },
  FloatFooter = { fg = dim, bg = widget },
  Cursor = { fg = bg, bg = fg },
  CursorLine = { bg = "#242526" },
  CursorColumn = "CursorLine",
  ColorColumn = { bg = panel },
  LineNr = { fg = "#858889" },
  CursorLineNr = { fg = fg },
  SignColumn = { fg = dim },
  FoldColumn = { fg = dim },
  Folded = { fg = dim, bg = over("#2767824D") },
  Visual = { bg = selection },
  Search = { bg = over("#27678280") },
  CurSearch = { fg = "#FFFFFF", bg = "#297AA0" },
  IncSearch = "CurSearch",
  Substitute = "CurSearch",
  MatchParen = { bg = over("#3994BC55") },
  -- Dim but readable: plugins use NonText for folder paths, counts, hidden files and hints.
  -- It's the gray VS Code uses for folder paths in Quick Open.
  NonText = { fg = dim },
  Whitespace = { fg = over("#8C8C8C4D") }, -- tab and trailing-space markers stay faint
  EndOfBuffer = { fg = bg },
  SpecialKey = { fg = dim },
  Conceal = { fg = dim },
  WinSeparator = { fg = border },
  StatusLine = { fg = dim, bg = panel },
  StatusLineNC = { fg = dim, bg = bg },
  TabLine = { fg = dim, bg = panel },
  TabLineFill = { bg = panel },
  TabLineSel = { fg = ui, bg = bg },
  WinBar = { fg = dim, bg = bg },
  WinBarNC = "WinBar",
  Pmenu = { fg = ui, bg = widget },
  PmenuSel = { bg = over("#FFFFFF26", widget) },
  PmenuSbar = { bg = widget },
  PmenuThumb = { bg = over("#A8A9AA85", widget) },
  PmenuMatch = { fg = blue },
  WildMenu = "PmenuSel",
  QuickFixLine = { bg = over("#27678260") },
  Directory = { fg = blue },
  Title = { fg = c.constant, bold = true },
  Question = { fg = blue },
  MoreMsg = { fg = blue },
  ModeMsg = { fg = ui },
  ErrorMsg = { fg = red },
  WarningMsg = { fg = yellow },
  SpellBad = { undercurl = true, sp = "#F14C4C" },
  SpellCap = { undercurl = true, sp = "#CCA700" },
  SpellRare = { undercurl = true, sp = "#3794FF" },
  SpellLocal = { undercurl = true, sp = "#3794FF" },

  -- Syntax
  Comment = { fg = c.comment },
  String = { fg = c.string },
  Character = "String",
  Number = { fg = c.number },
  Float = "Number",
  Boolean = { fg = c.literal },
  Constant = { fg = c.constant },
  Identifier = { fg = c.variable },
  Function = { fg = c.func },
  Statement = { fg = c.keyword },
  Keyword = { fg = c.keyword },
  Conditional = { fg = c.control },
  Repeat = "Conditional",
  Exception = "Conditional",
  Label = "Conditional",
  Operator = { fg = c.operator },
  PreProc = { fg = c.control },
  Define = { fg = c.literal },
  Macro = "Define",
  Type = { fg = c.type },
  StorageClass = { fg = c.literal },
  Structure = "Keyword",
  Typedef = "Keyword",
  Special = { fg = c.constant },
  SpecialChar = { fg = c.escape },
  Tag = { fg = c.tag },
  Delimiter = { fg = c.variable },
  Underlined = { fg = blue, underline = true },
  Error = { fg = "#f44747" },
  Todo = { fg = c.constant, bold = true },

  -- Treesitter
  ["@variable"] = { fg = c.variable },
  ["@variable.builtin"] = { fg = c.constant }, -- this, self
  ["@variable.parameter"] = { fg = c.parameter },
  ["@variable.member"] = "@variable",
  ["@property"] = "@variable",
  ["@property.json"] = { fg = c.tag },
  ["@property.jsonc"] = "@property.json",
  ["@property.yaml"] = "@property.json",
  ["@constant"] = "Constant",
  ["@constant.builtin"] = { fg = c.literal },
  ["@constant.macro"] = "Macro",
  ["@module"] = "Type",
  ["@label"] = { fg = "#C8C8C8" },
  ["@string.escape"] = "SpecialChar",
  ["@string.regexp"] = "String",
  ["@string.special.url"] = { fg = c.string, underline = true },
  ["@type.builtin"] = "Type",
  ["@attribute"] = "Function",
  ["@function.builtin"] = { fg = c.builtin },
  ["@function.macro"] = "Macro",
  ["@constructor"] = "Type",
  ["@constructor.lua"] = "Delimiter", -- the { } of a table
  ["@keyword.function"] = "Keyword",
  ["@keyword.type"] = "Keyword",
  ["@keyword.modifier"] = { fg = c.literal },
  ["@keyword.operator"] = { fg = c.literal },
  ["@keyword.conditional"] = "Conditional",
  ["@keyword.repeat"] = "Conditional",
  ["@keyword.exception"] = "Conditional",
  ["@keyword.return"] = "Conditional",
  ["@keyword.import"] = "Conditional",
  ["@keyword.coroutine"] = "Conditional",
  ["@keyword.conditional.ternary"] = "Operator",
  ["@punctuation.special"] = { fg = c.literal }, -- ${ } in a template string
  ["@tag"] = "Tag",
  ["@tag.builtin"] = "Tag",
  ["@tag.attribute"] = { fg = c.attribute },
  ["@tag.delimiter"] = { fg = "#808080" },
  ["@markup.heading"] = "Title",
  ["@markup.strong"] = { fg = c.variable, bold = true },
  ["@markup.italic"] = { fg = c.variable, italic = true },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.quote"] = { fg = c.tag },
  ["@markup.raw"] = { fg = c.constant },
  ["@markup.link"] = { fg = c.string },
  ["@markup.link.url"] = "@string.special.url",
  ["@markup.list"] = { fg = c.parameter },
  ["@diff.plus"] = { fg = c.tag },
  ["@diff.minus"] = { fg = "#ffa198" },
  ["@diff.delta"] = { fg = c.parameter },

  -- Language servers. VS Code lets these win over the grammar too, except where the grammar
  -- knows more (which kind of keyword, escapes inside a string).
  ["@lsp.type.keyword"] = {},
  ["@lsp.type.string"] = {},
  ["@lsp.type.comment"] = {},
  ["@lsp.type.operator"] = {},
  ["@lsp.type.macro"] = "Macro",
  ["@lsp.type.typeParameter"] = "Type",
  ["@lsp.typemod.variable.readonly"] = "Constant",
  ["@lsp.typemod.property.readonly"] = "Constant",
  ["@lsp.typemod.variable.defaultLibrary"] = "Constant", -- console, Math
  ["@lsp.typemod.function.defaultLibrary"] = "@function.builtin",
  LspReferenceText = { bg = over("#27678250") },
  LspReferenceRead = "LspReferenceText",
  LspReferenceWrite = { bg = over("#27678280") },
  LspInlayHint = { fg = "#969696", bg = over("#6161611A") },
  LspCodeLens = { fg = dim },
  LspSignatureActiveParameter = { fg = blue, bold = true },

  -- Diagnostics
  DiagnosticError = { fg = "#F14C4C" },
  DiagnosticWarn = { fg = "#CCA700" },
  DiagnosticInfo = { fg = "#3794FF" },
  DiagnosticHint = { fg = dim },
  DiagnosticOk = { fg = green },
  DiagnosticUnderlineError = { undercurl = true, sp = "#F14C4C" },
  DiagnosticUnderlineWarn = { undercurl = true, sp = "#CCA700" },
  DiagnosticUnderlineInfo = { undercurl = true, sp = "#3794FF" },
  DiagnosticUnderlineHint = { undercurl = true, sp = dim },
  DiagnosticUnnecessary = { fg = over("#BBBEBFAA") },
  DiagnosticDeprecated = { strikethrough = true },

  -- Diffs and git
  DiffAdd = { bg = over("#347d3926") },
  DiffChange = { bg = over("#347d3926") },
  DiffText = { bg = over("#57ab5a4d") },
  DiffDelete = { bg = over("#c93c3726") },
  Added = { fg = green },
  Changed = { fg = yellow },
  Removed = { fg = red },
  GitSignsAdd = { fg = signs.Add },
  GitSignsChange = { fg = signs.Change },
  GitSignsDelete = { fg = signs.Delete },
  GitSignsCurrentLineBlame = "NonText",

  -- Plugins (everything else follows the groups above)
  SnacksIndent = { fg = over("#8384854D") },
  SnacksIndentScope = { fg = "#838485" },
  SnacksPickerDirectory = { fg = ui }, -- folders in the file tree are plain text, as in VS Code
  SnacksPickerMatch = { fg = blue },
  SnacksPickerListCursorLine = { bg = over("#FFFFFF22", widget) },
  BlinkCmpLabelMatch = { fg = blue },
  BlinkCmpGhostText = { fg = over("#FFFFFF56") }, -- the completion preview after the cursor
  TreesitterContext = { bg = bg },
  TreesitterContextBottom = { underline = true, sp = border },
  TreesitterContextLineNumber = { fg = "#858889", bg = bg },
  MiniIconsAzure = { fg = "#57A3F8" },
  MiniIconsBlue = { fg = "#3794FF" },
  MiniIconsCyan = { fg = c.type },
  MiniIconsGreen = { fg = "#86CF86" },
  MiniIconsGrey = { fg = dim },
  MiniIconsOrange = { fg = "#CD861A" },
  MiniIconsPurple = { fg = "#AD80D7" },
  MiniIconsRed = { fg = "#EF8773" },
  MiniIconsYellow = { fg = "#E0B97F" },
}

-- Staged changes: a little dimmer than unstaged ones. Left to gitsigns, they get half the
-- brightness, which turns the blue almost black.
signs.Untracked, signs.Changedelete, signs.Topdelete = signs.Add, signs.Change, signs.Delete
for kind, color in pairs(signs) do
  for _, suffix in ipairs({ "", "Nr", "Cul" }) do
    groups["GitSignsStaged" .. kind .. suffix] = { fg = over(color .. "CC") }
  end
end

for name, hl in pairs(groups) do
  vim.api.nvim_set_hl(0, name, type(hl) == "string" and { link = hl } or hl)
end

-- :terminal colors: VS Code's terminal palette (black, red, green, yellow, blue, magenta, cyan, white)
local ansi = {
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
for i, color in ipairs(ansi) do
  vim.g["terminal_color_" .. i - 1] = color
end
