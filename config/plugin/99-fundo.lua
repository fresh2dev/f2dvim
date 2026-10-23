vim.pack.add({
  { src = "https://github.com/kevinhwang91/nvim-fundo" },
  { src = "https://github.com/kevinhwang91/promise-async" },
})

-- fundo needs 'undofile' (set in init.lua). It keeps the undo history usable after
-- the file changes outside Neovim.
local fundo = require("fundo")
fundo.install()
fundo.setup({
  -- In MB; the oldest archives are removed first.
  limit_archives_size = 512,
})
