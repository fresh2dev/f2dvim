vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons" },
})

require("mini.icons").setup({})

-- Stands in for nvim-web-devicons (not installed) for plugins without a mini.icons
-- integration. `90-` so the mock exists before any `99-` plugin requires it.
MiniIcons.mock_nvim_web_devicons()
