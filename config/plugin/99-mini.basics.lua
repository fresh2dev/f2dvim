vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.basics" },
})

require("mini.basics").setup({
  options = {
    basic = false,
    extra_ui = false,
    win_borders = "bold",
  },
  mappings = {
    basic = false,
    option_toggle_prefix = "",
    move_with_alt = false,
    -- `<C-hjkl>` window navigation and `<C-Arrow>` resizing
    windows = true,
  },
  autocommands = {
    basic = false,
    -- Set 'relativenumber' only in linewise and blockwise Visual mode
    relnum_in_visual_mode = true,
  },
  -- Whether to disable showing non-error feedback
  silent = true,
})

-- `<A-hjkl>` mirrors `<C-hjkl>` (an exception to the no-Alt rule).
for _, dir in ipairs({ "h", "j", "k", "l" }) do
  vim.keymap.set("n", "<A-" .. dir .. ">", "<C-w>" .. dir, {
    desc = "Focus window "
      .. ({ h = "left", j = "below", k = "above", l = "right" })[dir],
  })
end
