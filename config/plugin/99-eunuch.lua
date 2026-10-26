-- Must be set *before* loading the plugin.
-- https://github.com/tpope/vim-eunuch/issues/95#issuecomment-1183890098
vim.g.eunuch_no_maps = 1

vim.pack.add({
  { src = "https://github.com/tpope/vim-eunuch" },
  { src = "https://github.com/folke/snacks.nvim" },
})

Snacks = require("snacks")

-- Replaces eunuch's `:Rename` (defined when the plugin was added above) with
-- Snacks', so language servers see the rename and update imports.
vim.api.nvim_create_user_command("Rename", function(opts)
  local to -- Snacks prompts when nil
  if opts.args ~= "" then -- like eunuch: relative to the file's directory
    to = opts.args:find("^[~/]") and vim.fs.normalize(opts.args)
      or vim.fs.joinpath(vim.fn.expand("%:p:h"), opts.args)
  end
  Snacks.rename.rename_file({ to = to })
end, { nargs = "?", complete = "file", desc = "Rename the file (LSP-aware, Snacks)" })
