-- Snacks terminal and lazygit, and the keymaps that run commands in a floating
-- terminal. `Snacks.setup` is in 99-snacks.lua; see there.
vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

Snacks = require("snacks")
local util = require("util")

Snacks.config.terminal = { enabled = true }
Snacks.config.lazygit = {
  enabled = true,
  -- Don't generate a lazygit config (theme, editing in this Neovim); lazygit's
  -- own config applies.
  configure = false,
}

vim.keymap.set("t", "<C-w>", "<C-\\><C-n><C-w>", { desc = "Window Navigation" })

vim.keymap.set("n", "<leader>`", function()
  Snacks.terminal(nil, { win = { position = "bottom" } })
end, { desc = "Toggle terminal (below)" })

vim.keymap.set("n", "<leader>tt", util.float_terminal, {
  desc = "[T]oggle [F]loating terminal",
})

vim.keymap.set("n", "<leader>gg", function()
  Snacks.lazygit()
end, { desc = "LazyGit" })

vim.keymap.set("n", "<leader>fp", util.sessions, { desc = "[F]ind [P]roject" })

-- TODO: add commands `:LazyGit [<args>]` `:Just [<args>]`, `:J [<args>]`

-- TODO: *replace* this with a command named `:Just`
vim.keymap.set("n", "<leader>J", function()
  Snacks.terminal({ "just" })
end, { desc = "[J]ust Command Runner" })
