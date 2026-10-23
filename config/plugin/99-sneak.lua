vim.pack.add({
  { src = "https://github.com/justinmk/vim-sneak" },
})

-- No operator-pending maps: `s` there would collide with `ys`/`ds`/`cs`. `S` is
-- normal mode only, because visual `S` is mini.surround's "surround selection".
vim.keymap.set("n", "S", "<Plug>Sneak_S", { desc = "Sneak backward" })
vim.keymap.set({ "n", "x" }, "s", "<Plug>Sneak_s", { desc = "Sneak forward" })

vim.keymap.set({ "n", "x", "o" }, "f", "<Plug>Sneak_f", { desc = "Find char forward" })
vim.keymap.set({ "n", "x", "o" }, "F", "<Plug>Sneak_F", { desc = "Find char backward" })
vim.keymap.set({ "n", "x", "o" }, "t", "<Plug>Sneak_t", { desc = "Till char forward" })
vim.keymap.set({ "n", "x", "o" }, "T", "<Plug>Sneak_T", { desc = "Till char backward" })

vim.keymap.set(
  { "n", "x" },
  ";",
  "<Plug>Sneak_;",
  { desc = "Repeat sneak/f/t forward" }
)
vim.keymap.set(
  { "n", "x" },
  ",",
  "<Plug>Sneak_,",
  { desc = "Repeat sneak/f/t backward" }
)
