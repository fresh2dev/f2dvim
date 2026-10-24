-- Must be set *before* loading the plugin.
-- https://github.com/tpope/vim-eunuch/issues/95#issuecomment-1183890098
vim.g.eunuch_no_maps = 1

vim.pack.add({
  { src = "https://github.com/tpope/vim-eunuch" },
})
