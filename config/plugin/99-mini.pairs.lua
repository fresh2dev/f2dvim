vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.pairs" },
})

-- The neighbourhood is "<left><right>", with "\r"/"\n" for line start/end. As in
-- nvim-autopairs, never pair right before a word or one of `%'["`.$`. Quotes also
-- never pair right after a word or the same quote, so typing a ``` fence or a
-- """ / ''' docstring gives exactly three.
local next_ok = "[^%w%%'%[\"%.`%$]$"
local open = { neigh_pattern = next_ok }
local close = { neigh_pattern = ".." } -- jump over the closer even after `\`
local function quote(char)
  return { neigh_pattern = "^[^%w" .. char .. "]" .. next_ok, register = { cr = true } }
end

require("mini.pairs").setup({
  mappings = {
    ["("] = open,
    ["["] = open,
    ["{"] = open,
    [")"] = close,
    ["]"] = close,
    ["}"] = close,
    ['"'] = quote('"'),
    ["`"] = quote("`"),
    ["'"] = quote("'"),
  },
})
