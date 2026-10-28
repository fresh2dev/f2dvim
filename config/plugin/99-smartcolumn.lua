-- Named after smartcolumn.nvim, which does the same; no plugin is installed.
-- Colour the column after 'textwidth' (editorconfig's max_line_length sets it, e.g.
-- 88 for Python) only while some line runs past it.
-- shortcut: scans the whole buffer on every change, add a line-count cap if large
-- files lag.
vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
  desc = "Show the column after 'textwidth' only when a line exceeds it",
  group = vim.api.nvim_create_augroup("smart-colorcolumn", { clear = true }),
  callback = function()
    local tw = vim.bo.textwidth
    local exceeded = vim.bo.buftype == ""
      and tw > 0
      and vim.fn.search([[\%>]] .. tw .. "v.", "nw") > 0
    vim.wo.colorcolumn = exceeded and "+1" or ""
  end,
})
