-- "Dark 2026", VS Code's default dark theme, for Neovim, so code looks the same in both editors.
-- The colors are in theme/palette.lua (shared with lazygit, delta and bat); this file says which
-- one each part of Neovim gets. The status line is lua/lualine/themes/dark2026.lua.
vim.o.background = "dark"
vim.cmd("highlight clear")
vim.g.colors_name = "dark2026"

-- ~/.config/nvim is a link to the repo's nvim/, and palette.lua is next to it in the repo
local p = dofile(vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath("config"))) .. "/theme/palette.lua")
local over, c = p.over, p.syntax
local bg, fg, widget, border, ui, dim = p.bg, p.fg, p.widget, p.border, p.ui, p.dim
local selection = over(p.selection)

-- Git changes in the sign column
local signs = { Add = p.gutter.add, Change = p.gutter.change, Delete = p.gutter.delete }

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
  CursorLine = { bg = p.line },
  CursorColumn = "CursorLine",
  ColorColumn = { bg = p.panel },
  LineNr = { fg = p.line_nr },
  CursorLineNr = { fg = fg },
  SignColumn = { fg = dim },
  FoldColumn = { fg = dim },
  Folded = { fg = dim, bg = over(p.fold) },
  Visual = { bg = selection },
  Search = { bg = over(p.search) },
  CurSearch = { fg = p.on_button, bg = p.button },
  IncSearch = "CurSearch",
  Substitute = "CurSearch",
  MatchParen = { bg = over(p.bracket) },
  -- Dim but readable: plugins use NonText for folder paths, counts, hidden files and hints.
  -- It's the gray VS Code uses for folder paths in Quick Open.
  NonText = { fg = dim },
  Whitespace = { fg = over(p.whitespace) }, -- tab and trailing-space markers stay faint
  EndOfBuffer = { fg = bg },
  SpecialKey = { fg = dim },
  Conceal = { fg = dim },
  WinSeparator = { fg = border },
  StatusLine = { fg = dim, bg = p.panel },
  StatusLineNC = { fg = dim, bg = bg },
  TabLine = { fg = dim, bg = p.panel },
  TabLineFill = { bg = p.panel },
  TabLineSel = { fg = ui, bg = bg },
  WinBar = { fg = dim, bg = bg },
  WinBarNC = "WinBar",
  Pmenu = { fg = ui, bg = widget },
  PmenuSel = { bg = over(p.menu_selection, widget) },
  PmenuSbar = { bg = widget },
  PmenuThumb = { bg = over(p.scrollbar, widget) },
  PmenuMatch = { fg = p.blue },
  WildMenu = "PmenuSel",
  QuickFixLine = { bg = over(p.quickfix) },
  Directory = { fg = p.blue },
  Title = { fg = c.constant, bold = true },
  Question = { fg = p.blue },
  MoreMsg = { fg = p.blue },
  ModeMsg = { fg = ui },
  ErrorMsg = { fg = p.red },
  WarningMsg = { fg = p.yellow },
  SpellBad = { undercurl = true, sp = p.error },
  SpellCap = { undercurl = true, sp = p.warning },
  SpellRare = { undercurl = true, sp = p.info },
  SpellLocal = { undercurl = true, sp = p.info },

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
  Underlined = { fg = p.blue, underline = true },
  Error = { fg = c.invalid },
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
  ["@label"] = { fg = c.label },
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
  ["@tag.delimiter"] = { fg = c.tag_delimiter },
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
  ["@diff.minus"] = { fg = c.deleted },
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
  LspReferenceText = { bg = over(p.word) },
  LspReferenceRead = "LspReferenceText",
  LspReferenceWrite = { bg = over(p.word_write) },
  LspInlayHint = { fg = p.inlay_hint, bg = over(p.inlay_hint_bg) },
  LspCodeLens = { fg = dim },
  LspSignatureActiveParameter = { fg = p.blue, bold = true },

  -- Diagnostics
  DiagnosticError = { fg = p.error },
  DiagnosticWarn = { fg = p.warning },
  DiagnosticInfo = { fg = p.info },
  DiagnosticHint = { fg = dim },
  DiagnosticOk = { fg = p.green },
  DiagnosticUnderlineError = { undercurl = true, sp = p.error },
  DiagnosticUnderlineWarn = { undercurl = true, sp = p.warning },
  DiagnosticUnderlineInfo = { undercurl = true, sp = p.info },
  DiagnosticUnderlineHint = { undercurl = true, sp = dim },
  DiagnosticUnnecessary = { fg = over(p.unnecessary) },
  DiagnosticDeprecated = { strikethrough = true },

  -- Diffs and git
  DiffAdd = { bg = over(p.diff.add) },
  DiffChange = { bg = over(p.diff.add) },
  DiffText = { bg = over(p.diff.add_text) },
  DiffDelete = { bg = over(p.diff.delete) },
  Added = { fg = p.green },
  Changed = { fg = p.yellow },
  Removed = { fg = p.red },
  GitSignsAdd = { fg = signs.Add },
  GitSignsChange = { fg = signs.Change },
  GitSignsDelete = { fg = signs.Delete },
  GitSignsCurrentLineBlame = "NonText",

  -- Plugins (everything else follows the groups above)
  SnacksIndent = { fg = over(p.indent) },
  SnacksIndentScope = { fg = p.indent_active },
  SnacksPickerDirectory = { fg = ui }, -- folders in the file tree are plain text, as in VS Code
  SnacksPickerMatch = { fg = p.blue },
  SnacksPickerListCursorLine = { bg = over(p.list_selection, widget) },
  BlinkCmpLabelMatch = { fg = p.blue },
  BlinkCmpGhostText = { fg = over(p.ghost_text) },
  TreesitterContext = { bg = bg },
  TreesitterContextBottom = { underline = true, sp = border },
  TreesitterContextLineNumber = { fg = p.line_nr, bg = bg },
  MiniIconsAzure = { fg = p.icons.azure },
  MiniIconsBlue = { fg = p.info },
  MiniIconsCyan = { fg = c.type },
  MiniIconsGreen = { fg = p.icons.green },
  MiniIconsGrey = { fg = dim },
  MiniIconsOrange = { fg = p.icons.orange },
  MiniIconsPurple = { fg = p.icons.purple },
  MiniIconsRed = { fg = p.icons.red },
  MiniIconsYellow = { fg = p.icons.yellow },
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

-- :terminal colors: VS Code's terminal palette
for i, color in ipairs(p.ansi) do
  vim.g["terminal_color_" .. i - 1] = color
end
