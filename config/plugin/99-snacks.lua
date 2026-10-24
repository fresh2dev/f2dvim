-- snacks.nvim: the one `Snacks.setup` call, the small modules and the toggles.
-- Like mini's, the bigger modules have their own `99-snacks.<module>.lua` files.
-- Those set `Snacks.config.<module>` (with `enabled = true`) instead of passing
-- it here: Snacks reads a module's config when the module starts (`UIEnter`, after
-- every plugin file) or is first used, so they work on either side of this file.
-- `notifier` and `statuscolumn` are read by `Snacks.setup` itself, so stay here.
vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

Snacks = require("snacks")

Snacks.setup({
  animate = { enabled = false },
  bigfile = { enabled = true },
  -- Guides only: mini.indentscope draws the current scope.
  indent = { enabled = true, scope = { enabled = false } },
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 5000,
    style = "minimal",
  },
  quickfile = { enabled = false }, -- Doesn't make much of a difference.
  scratch = { enabled = false },
  scroll = { enabled = false }, -- Buggy.
  statuscolumn = { enabled = true },
  words = { enabled = true },
})

vim.g.snacks_animate = false

Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>ts")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>tw")
-- Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>tL'
Snacks.toggle.diagnostics():map("<leader>td")
-- Snacks.toggle.line_number():map '<leader>tl'
-- Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>tc'
-- Snacks.toggle.treesitter():map '<leader>tT'
-- Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>tb'
Snacks.toggle.inlay_hints():map("<leader>th")
Snacks.toggle.indent():map("<leader>ti")
-- Snacks.toggle.dim():map("<leader>tD")

-- vim.keymap.set({ 'n', 'x' }, '<leader>gB', Snacks.gitbrowse, { desc = "Git Browse" })
