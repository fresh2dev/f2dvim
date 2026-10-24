vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.splitjoin" },
})

-- Split / join arguments inside brackets, in Normal and Visual mode.
require("mini.splitjoin").setup({
  mappings = {
    toggle = "gS",
    split = "",
    join = "",
  },
})
