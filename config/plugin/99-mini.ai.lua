vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.ai" },
  { src = "https://github.com/nvim-mini/mini.extra" },
})

local MiniExtra = require("mini.extra")
MiniExtra.setup({})

local ai = require("mini.ai")

ai.setup({
  custom_textobjects = {
    -- Make `ae` / `ie` act on around/inside *e*ntire buffer
    e = MiniExtra.gen_ai_spec.buffer(),
    -- `aF`/`iF`: around/inside a function definition (not a call), via treesitter
    F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
  },

  -- Number of lines within which textobject is searched
  n_lines = 500,

  -- Module mappings. Use `''` (empty string) to disable one.
  mappings = {
    around = "a",
    inside = "i",
    around_next = "", -- 'an',
    inside_next = "", -- 'in',
    around_last = "", -- 'al',
    inside_last = "", -- 'il',
    -- Move cursor to corresponding edge of `a` textobject
    goto_left = "g[",
    goto_right = "g]",
  },
})
