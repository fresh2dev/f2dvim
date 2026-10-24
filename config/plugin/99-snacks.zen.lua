-- Snacks zen and zoom. `Snacks.setup` is in 99-snacks.lua; see there.
vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

Snacks = require("snacks")

Snacks.config.zen = {
  enabled = true,
  toggles = {
    dim = false,
    git_signs = false,
    mini_diff_signs = false,
    diagnostics = false,
    inlay_hints = false,
  },
  show = {
    statusline = true, -- can only be shown when using the global statusline
    tabline = false,
  },
  win = {
    style = "zen",
    backdrop = { transparent = false, blend = 0 },
    width = 0.8,
  },
  zoom = {
    toggles = {},
    show = {
      statusline = true,
      tabline = true,
    },
    win = {
      style = "zen",
      backdrop = { transparent = false, blend = 0 },
      width = 0.8,
    },
  },
}

--- Map `lhs` to `Snacks.zen[mode]`, which also turns off line numbers.
local function map(lhs, mode, desc)
  vim.keymap.set("n", lhs, function()
    Snacks.zen[mode]()
    vim.cmd("setlocal nonumber")
  end, { desc = desc })
end

map("<leader>tz", "zoom", "[T]oggle [Z]oom")
map("gz", "zoom", "[G]o [Z]oom")
map("<leader>tZ", "zen", "[T]oggle [Z]en-Mode")
map("gZ", "zen", "[G]o [Z]en")
