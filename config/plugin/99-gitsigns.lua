vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

local gitsigns = require("gitsigns")

gitsigns.setup({
  signs = {
    add = { text = "┃" },
    change = { text = "┃" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "┆" },
  },
  preview_config = {
    -- Options passed to nvim_open_win
    style = "minimal",
    relative = "cursor",
    anchor = "NW",
    row = -5,
    col = 1,
  },
  signcolumn = true,
  numhl = true,
  linehl = false,
  word_diff = false,
  on_attach = function(bufnr)
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next", { preview = true, target = "all" })
      end
    end)

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev", { preview = true, target = "all" })
      end
    end)
  end,
})
