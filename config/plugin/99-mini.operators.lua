vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.operators" },
})

local operators = require("mini.operators")

operators.setup({
  -- `prefix` maps the operator in Normal mode (textobject and line) and in Visual
  -- mode (selection); `""` maps nothing.

  -- Evaluate text and replace with output
  evaluate = {
    prefix = "",

    func = nil,
  },

  -- Exchange text regions. Mapped manually below (`cx` in normal mode, `X` in
  -- visual mode) because a visual-mode `cx` makes `c` wait for 'timeoutlen'.
  exchange = {
    prefix = "",

    reindent_linewise = true,
  },

  -- Multiply (duplicate) text
  multiply = {
    prefix = "gm",

    func = nil,
  },

  -- Replace text with register
  replace = {
    -- Not the default `gr`: that is Neovim's LSP prefix.
    prefix = "<leader>p",

    reindent_linewise = true,
  },

  -- Sort text
  sort = {
    prefix = "gs",

    func = nil,
  },
})

-- Exchange: `cx{motion}` / `cxx` in normal mode, `X` on a visual selection.
-- Not `cx` in visual mode: 99-cutlass.lua maps visual `c`, so a visual `cx` would
-- make every visual `c` pause for 'timeoutlen' before changing the text. Visual `X`
-- shadows 99-cutlass.lua's linewise delete into the blackhole register (`"_X`); use
-- `D` or `d` for that instead.
operators.make_mappings("exchange", {
  textobject = "cx",
  line = "cxx",
  selection = "X",
})

-- Replace to end of line: `<leader>P` is to `<leader>p` what `D`/`C` are to `d`/`c`.
vim.keymap.set("n", "<leader>P", "<leader>p$", {
  remap = true,
  desc = "Replace to end of line",
})
