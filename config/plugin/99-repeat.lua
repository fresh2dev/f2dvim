vim.pack.add({
  { src = "https://github.com/tpope/vim-repeat" },
})

-- vim-repeat's autoload script maps `.` to `<Plug>(RepeatDot)` when it first loads
-- (the first `repeat#set`), which would replace the mapping below; load it now.
vim.cmd.runtime("autoload/repeat.vim")

-- Dot-repeat that keeps the cursor on the text it was on. A [count] is passed
-- through only when given, so a bare `.` still reuses the original count.
vim.keymap.set("n", ".", function()
  if vim.g.repeat_tick == vim.b.changedtick then -- a vim-repeat mapping is pending
    return vim.fn["repeat#run"](vim.v.count)
  end
  local count = vim.v.count > 0 and vim.v.count or ""
  require("util").keep_cursor(function()
    vim.cmd("normal! " .. count .. ".")
  end)
end, { desc = "Repeat (keep cursor)" })
