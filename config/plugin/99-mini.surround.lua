vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.surround" },
})

require("mini.surround").setup({
  custom_surroundings = {
    -- Surround in triple backticks (markdown code block)
    c = { input = { "```\n().-()\n```" }, output = { left = "```\n", right = "\n```" } },
  },

  highlight_duration = 500,

  -- Map as is done in tpope/vim-surround
  mappings = {
    add = "ys",
    delete = "ds",
    find = "",
    find_left = "",
    highlight = "",
    replace = "cs",
    update_n_lines = "",

    suffix_last = "",
    suffix_next = "",
  },

  -- Number of lines within which surrounding is searched
  n_lines = 25,

  respect_selection_type = false,

  search_method = "cover",

  silent = false,
})

-- Visual `S` replaces visual `ys`. It must be a `:<C-u>` command mapping, not a
-- Lua callback: the command leaves Visual mode first, which is what updates the
-- `'<`/`'>` marks that `MiniSurround.add("visual")` reads. Calling it from a
-- callback while still in Visual mode reads the previous selection's marks
-- (possibly out of range).
vim.keymap.del("x", "ys")
vim.keymap.set(
  "x",
  "S",
  [[:<C-u>lua MiniSurround.add("visual")<CR>]],
  { silent = true, desc = "Surround selection" }
)

vim.keymap.set("n", "yss", "ys_", { remap = true, desc = "Surround line" })
