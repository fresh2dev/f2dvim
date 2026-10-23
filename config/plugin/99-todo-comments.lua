vim.pack.add({
  { src = "https://github.com/folke/todo-comments.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
})

require("todo-comments").setup({
  signs = false,
  highlight = {
    pattern = ".*<(KEYWORDS):", -- vim regex
    before = "",
    keyword = "wide",
    after = "fg",
  },
  keywords = {
    TODO = { icon = "☐ ", color = "warning" },
    NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
  },
  gui_style = {
    fg = "NONE",
    bg = "BOLD",
  },
  merge_keywords = true, -- keep the default keywords too

  search = {
    args = {
      "--color=never",
      "--case-sensitive",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
    },
    -- pattern = [[\bTODO(:|!)]], -- ripgrep regex
    -- Highlight various types, but only include 'TODO'
    -- in search results.
    pattern = [[\bTODO:]], -- ripgrep regex
  },
})
