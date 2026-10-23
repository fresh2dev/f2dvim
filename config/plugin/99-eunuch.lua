vim.pack.add({
  { src = "https://github.com/tpope/vim-eunuch" },
})

-- Otherwise eunuch wraps the insert-mode <CR> mapping that blink and autopairs own:
-- https://github.com/tpope/vim-eunuch/issues/95#issuecomment-1183890098
vim.g.eunuch_no_maps = 1
