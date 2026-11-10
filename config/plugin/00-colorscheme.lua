vim.pack.add({
  {
    src = "https://github.com/EdenEast/nightfox.nvim",
    -- -- Version constraint, see: https://neovim.io/doc/user/lua/#version-range
    -- version = vim.version.range("1.*"),
    -- -- Use wildcard for any tagged release
    -- version = vim.version.range("*"),
    -- -- Git branch, tag, or commit hash
    -- version = "main",
    -- (When no `version` is specified, the default branch is used)
  },
})

-- bg1 is the Normal background, bg0 the statusline and floats.
require("nightfox").setup({
  palettes = { all = { bg0 = "#000000", bg1 = "#000000" } },
})

vim.cmd.colorscheme("carbonfox")
