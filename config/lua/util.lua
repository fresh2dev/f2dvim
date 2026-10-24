-- Cross-file helpers. This is the only module under `lua/`; plugin
-- configuration lives in `plugin/*.lua`, never here.
local M = {}

--- Abbreviate `lhs` to `rhs` on the `:` command line, but only when `lhs` is
--- the whole line typed so far (so `:grep` becomes `:Grep` while `:vimgrep`
--- and `:'<,'>grep` are left alone).
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

--- Run `fn` and put the cursor back on the text it was on beforehand. The
--- position is tracked with an extmark rather than saved as a row/col, so it
--- follows the text when `fn` inserts or deletes lines above the cursor, and
--- it cannot end up out of range when `fn` deletes the cursor's own line.
--- The cursor is restored even if `fn` errors; the error is then re-raised.
---@param fn fun()
function M.keep_cursor(fn)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  local id = vim.api.nvim_buf_set_extmark(buf, keep_cursor_ns, row - 1, col, {})

  local ok, err = pcall(fn)

  if vim.api.nvim_buf_is_valid(buf) then
    local pos = vim.api.nvim_buf_get_extmark_by_id(buf, keep_cursor_ns, id, {})
    vim.api.nvim_buf_del_extmark(buf, keep_cursor_ns, id)
    if
      pos[1]
      and vim.api.nvim_win_is_valid(win)
      and vim.api.nvim_win_get_buf(win) == buf
    then
      vim.api.nvim_win_set_cursor(win, { pos[1] + 1, pos[2] })
    end
  end
  if not ok then
    error(err, 0)
  end
end

--- Run `cmd` in a floating zellij pane inside zellij, else in a Snacks terminal
--- (or `fallback`, such as Snacks.lazygit). Either closes when `cmd` exits. The
--- zellij pane is titled `name`, else `cmd[1]`.
---@param cmd string[]
---@param fallback? fun()
---@param name? string
function M.terminal(cmd, fallback, name)
  if not vim.env.ZELLIJ then
    if fallback then
      fallback()
    else
      Snacks.terminal(cmd)
    end
    return
  end
  -- stylua: ignore
  local args = {
    "zellij", "run", "--floating", "--close-on-exit", "--name", name or cmd[1],
    "--cwd", vim.fn.getcwd(), "--x", "5%", "--y", "5%", "--width", "90%", "--height", "90%",
    "--",
  }
  vim.system(vim.list_extend(args, cmd), {}, function(res)
    if res.code ~= 0 then
      vim.schedule(function()
        vim.notify(vim.trim(res.stderr), vim.log.levels.ERROR)
      end)
    end
  end)
end

--- Open the fzj session picker with `M.terminal`. In its own zellij pane, fzj
--- needs `--here`; otherwise it opens a second one.
function M.sessions()
  M.terminal(vim.env.ZELLIJ and { "fzj", "--here" } or { "fzj" })
end

return M
