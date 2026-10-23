vim.pack.add({
  { src = "https://github.com/chrisgrieser/nvim-various-textobjs" },
})

local various_textobjs = require("various-textobjs")

various_textobjs.setup({
  keymaps = {
    useDefaults = false,
  },
})

vim.keymap.set({ "o", "x" }, "av", function()
  various_textobjs.subword("outer")
end, { desc = "around subword" })
vim.keymap.set({ "o", "x" }, "iv", function()
  various_textobjs.subword("inner")
end, { desc = "inside subword" })
