-- Status line for the dark2026 colorscheme (colors/dark2026.lua): VS Code's status bar colors,
-- with the mode shown in the theme's accent blue (lualine picks this file up by its name).
local bar = { fg = "#8C8C8C", bg = "#191A1B" }
local raised = { fg = "#bfbfbf", bg = "#242526" }

local function mode(color)
  return { a = { fg = "#121314", bg = color, gui = "bold" }, b = raised, c = bar }
end

return {
  normal = mode("#48A0C7"),
  insert = mode("#73c991"),
  visual = mode("#C586C0"),
  replace = mode("#f48771"),
  command = mode("#e5ba7d"),
  terminal = mode("#73c991"),
  inactive = { a = bar, b = bar, c = bar },
}
