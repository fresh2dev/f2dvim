-- Jump to the start of the next / previous merge-conflict hunk. Like
-- rhysd/conflict-marker.vim, a hunk only counts when its `<<<<<<<`, `=======` and
-- `>>>>>>>` lines are all found, and from inside a hunk "previous" skips to the
-- hunk before it.
---@param forward boolean
local function jump_conflict(forward)
  local pos = vim.fn.getpos(".")
  local markers = forward and { "<<<<<<<", "=======", ">>>>>>>" }
    or { ">>>>>>>", "=======", "<<<<<<<" }
  local lines = {}
  for _, marker in ipairs(markers) do
    local lnum = vim.fn.search("^" .. marker, forward and "W" or "bW")
    if lnum == 0 then
      vim.fn.setpos(".", pos)
      return vim.notify("conflict not found", vim.log.levels.ERROR)
    end
    table.insert(lines, lnum)
  end
  vim.api.nvim_win_set_cursor(0, { forward and lines[1] or lines[3], 0 })
end

vim.keymap.set("n", "]x", function()
  jump_conflict(true)
end, { desc = "Next conflict" })
vim.keymap.set("n", "[x", function()
  jump_conflict(false)
end, { desc = "Previous conflict" })
