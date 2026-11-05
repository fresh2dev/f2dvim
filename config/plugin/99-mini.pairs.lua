vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.pairs" },
})

-- The neighbourhood is "<left><right>", with "\r"/"\n" for line start/end. As in
-- nvim-autopairs, never pair right before a word or one of `%'["`.$`. Quotes also
-- never pair right after a word, and a backtick never pairs right after a backtick,
-- so typing a ``` fence gives exactly three.
local next_ok = "[^%w%%'%[\"%.`%$]$"
local open = { neigh_pattern = next_ok }
local close = { neigh_pattern = ".." } -- jump over the closer even after `\`
local quote = { neigh_pattern = "^[^%w]" .. next_ok, register = { cr = true } }

require("mini.pairs").setup({
  mappings = {
    ["("] = open,
    ["["] = open,
    ["{"] = open,
    [")"] = close,
    ["]"] = close,
    ["}"] = close,
    ['"'] = quote,
    ["`"] = vim.tbl_extend("force", quote, { neigh_pattern = "^[^%w`]" .. next_ok }),
    ["'"] = quote,
  },
})
