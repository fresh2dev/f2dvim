-- Named after the sticky-yank tip that inspired it; no plugin is installed.
-- https://nanotipsforvim.prose.sh/sticky-yank
-- `y`/`Y` leave the cursor and the view where they were instead of jumping to the
-- start of the yanked text (`ygg` no longer scrolls away). The operator only runs
-- after the mapping returns, so the view is recorded here and restored from
-- TextYankPost. The record belongs to that one yank: it is dropped once the command
-- is over (yanked or cancelled with <Esc>), so yanks that don't come through these
-- keys (`:yank`, a plugin's `normal! y`) are left alone.

local pending -- { win, buf, view } of the mapped yank in progress

local function sticky(keys)
  return function()
    local win = vim.api.nvim_get_current_win()
    pending = {
      win = win,
      buf = vim.api.nvim_win_get_buf(win),
      view = vim.fn.winsaveview(),
    }
    return keys
  end
end
vim.keymap.set(
  { "n", "x" },
  "y",
  sticky("y"),
  { expr = true, desc = "Yank (keep cursor)" }
)
vim.keymap.set(
  "n",
  "Y",
  sticky("y$"),
  { expr = true, desc = "Yank to end of line (keep cursor)" }
)

local group = vim.api.nvim_create_augroup("sticky-yank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Restore the pre-yank cursor and view after a mapped yank",
  group = group,
  callback = function()
    local p = pending
    pending = nil
    if
      p
      and vim.v.event.operator == "y"
      and vim.api.nvim_get_current_win() == p.win
      and vim.api.nvim_get_current_buf() == p.buf
    then
      vim.fn.winrestview(p.view)
    end
  end,
})
-- Back in Normal mode means the yank is done or was cancelled (`y<Esc>`).
-- Deferred, since this can fire before TextYankPost.
vim.api.nvim_create_autocmd("ModeChanged", {
  desc = "Forget the pre-yank view once the yank is over",
  group = group,
  pattern = "*:n*",
  callback = function()
    vim.schedule(function()
      pending = nil
    end)
  end,
})
