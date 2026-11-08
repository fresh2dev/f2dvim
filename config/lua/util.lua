-- Cross-file helpers. This is the only module under `lua/`; plugin
-- configuration lives in `plugin/*.lua`, never here.
local M = {}

--- Abbreviate `lhs` to `rhs` on the `:` command line, but only when `lhs` is
--- the whole line typed so far (so `:git` becomes `:Git` while `:'<,'>git` is
--- left alone).
---@param lhs string
---@param rhs string
function M.cabbrev(lhs, rhs)
  vim.keymap.set("ca", lhs, function()
    if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == lhs then
      return rhs
    end
    return lhs
  end, { expr = true })
end

local keep_cursor_ns = vim.api.nvim_create_namespace("util.keep_cursor")

--- Remember the text under the cursor. Returns a function that puts the cursor
--- back on that text. The position is tracked with an extmark rather than saved
--- as a row/col, so it follows the text when lines are inserted or deleted above
--- the cursor. If the text under the cursor is replaced (native `gc` sets whole
--- lines, which would carry the extmark to the next line), it falls back to the
--- saved row and column, clamped to the buffer. The returned function works once
--- and does nothing if the window no longer shows the buffer.
---@return fun()
function M.mark_cursor()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  local id = vim.api.nvim_buf_set_extmark(
    buf,
    keep_cursor_ns,
    row - 1,
    col,
    { invalidate = true }
  )

  return function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local pos =
      vim.api.nvim_buf_get_extmark_by_id(buf, keep_cursor_ns, id, { details = true })
    vim.api.nvim_buf_del_extmark(buf, keep_cursor_ns, id)
    if
      pos[1]
      and vim.api.nvim_win_is_valid(win)
      and vim.api.nvim_win_get_buf(win) == buf
    then
      if pos[3].invalid then
        pos = { row - 1, col }
      end
      local last = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_win_set_cursor(win, { math.min(pos[1] + 1, last), pos[2] })
    end
  end
end

--- Run `fn` and put the cursor back on the text it was on beforehand (see
--- `mark_cursor`). Pass `restore` from an earlier `mark_cursor()` to return to
--- that position instead. The cursor is restored even if `fn` errors; the error
--- is then re-raised.
---@param fn fun()
---@param restore? fun()
function M.keep_cursor(fn, restore)
  restore = restore or M.mark_cursor()
  local ok, err = pcall(fn)
  restore()
  if not ok then
    error(err, 0)
  end
end

--- The 'tabline': each tab's number between plain spaces, centred. The number is
--- highlighted as the current or a background tab; `%{n}T` makes it clickable.
---@return string
function M.tabline()
  local current = vim.fn.tabpagenr()
  local line = "%#TabLineFill#%="
  for tab = 1, vim.fn.tabpagenr("$") do
    local hl = tab == current and "TabLineSel" or "TabLine"
    line = ("%s %%%dT%%#%s#%d%%#TabLineFill# "):format(line, tab, hl, tab)
  end
  return line .. "%T%="
end

return M
