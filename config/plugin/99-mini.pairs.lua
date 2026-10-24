vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.pairs" },
})

-- The neighbourhood is "<left><right>", with "\r"/"\n" for line start/end. As in
-- nvim-autopairs, never pair right before a word or one of `%'["`.$`.
local next_ok = "[^%w%%'%[\"%.`%$]$"
local open = { neigh_pattern = next_ok }
local close = { neigh_pattern = ".." } -- jump over the closer even after `\`
local quote = { neigh_pattern = next_ok, register = { cr = true } }

require("mini.pairs").setup({
  mappings = {
    ["("] = open,
    ["["] = open,
    ["{"] = open,
    [")"] = close,
    ["]"] = close,
    ["}"] = close,
    ['"'] = quote,
    ["`"] = quote,
    ["'"] = vim.tbl_extend("force", quote, { neigh_pattern = "^[^%w]" .. next_ok }),
  },
})
