-- Named after Comment.nvim, whose `gco`/`gcO` these copy; no plugin is installed.
-- Add a comment line above / below the current line and start inserting into
-- it. Neovim's `gcc` decides the comment leader (it is context-aware, e.g. for
-- Lua inside Markdown), so insert a placeholder line at the current indent,
-- let it comment that, then remove the placeholder and put the cursor there.
local function add_comment_line(where)
  return function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local indent = vim.api.nvim_get_current_line():match("^%s*")
    local at = where == "above" and row - 1 or row -- 0-based insertion index
    local placeholder = "\1" -- a byte that cannot already be in the comment
    vim.api.nvim_buf_set_lines(0, at, at, false, { indent .. placeholder })
    local new_row = at + 1
    vim.api.nvim_win_set_cursor(0, { new_row, 0 })
    vim.cmd.normal("gcc") -- remapped: runs the default `gcc`
    local line = vim.api.nvim_buf_get_lines(0, at, new_row, false)[1]
    local col = assert(line:find(placeholder, 1, true)) -- 1-based
    line = line:sub(1, col - 1) .. line:sub(col + 1)
    vim.api.nvim_buf_set_lines(0, at, new_row, false, { line })
    vim.api.nvim_win_set_cursor(0, { new_row, col - 1 })
    if col > #line then
      vim.cmd("startinsert!") -- placeholder was at the end of the line: append
    else
      vim.cmd("startinsert") -- inside a block comment: insert before the closer
    end
  end
end
vim.keymap.set(
  "n",
  "gco",
  add_comment_line("below"),
  { desc = "Add comment line below" }
)
vim.keymap.set(
  "n",
  "gcO",
  add_comment_line("above"),
  { desc = "Add comment line above" }
)
