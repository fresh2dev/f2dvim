vim.pack.add({
  { src = "https://github.com/junegunn/vim-easy-align" },
})

vim.keymap.set("x", "ga", "<Plug>(EasyAlign)", { desc = "Align selection" })
vim.keymap.set("n", "ga", "<Plug>(EasyAlign)", { desc = "Align (operator)" })
