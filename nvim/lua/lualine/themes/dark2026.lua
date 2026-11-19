-- Status line for the dark2026 colorscheme (colors/dark2026.lua): VS Code's status bar colors,
-- with the mode shown in the theme's accent blue (lualine picks this file up by its name).
-- The colors are in theme/palette.lua.
-- ~/.config/nvim is a link to the repo's nvim/, and palette.lua is next to it in the repo
local p = dofile(vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath("config"))) .. "/theme/palette.lua")
local bar = { fg = p.dim, bg = p.panel }
local raised = { fg = p.ui, bg = p.line }

local function mode(color)
  return { a = { fg = p.bg, bg = color, gui = "bold" }, b = raised, c = bar }
end

return {
  normal = mode(p.blue),
  insert = mode(p.green),
  visual = mode(p.syntax.control),
  replace = mode(p.red),
  command = mode(p.yellow),
  terminal = mode(p.green),
  inactive = { a = bar, b = bar, c = bar },
}
