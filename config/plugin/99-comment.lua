-- Named after Comment.nvim, whose `gco`/`gcO`/`gcA`/`gb` these copy; only
-- nvim-ts-context-commentstring is installed, for block comment strings.
vim.pack.add({
  { src = "https://github.com/JoosepAlviste/nvim-ts-context-commentstring" },
})

require("ts_context_commentstring").setup({
  enable_autocmd = false, -- native `gc` keeps Neovim's own 'commentstring'
  languages = { rust = { __default = "// %s", __multiline = "/* %s */" } },
})

-- Comment strings are read from the tree as it is, which is stale right after
-- an edit; reparse 0-based rows `first` to `last` (exclusive) so an injection
-- (a Markdown code block) covers them.
local function parse_rows(first, last)
  local parser = vim.treesitter.get_parser(0, nil, { error = false })
  if parser then
    parser:parse({ first, last })
  end
end

-- Neovim's `gcc` decides the comment leader (it is context-aware, e.g. for Lua
-- inside Markdown), so insert a placeholder line at `indent` at 0-based index
-- `at`, let `gcc` comment it, and remove it again. Returns the commented line
-- without the placeholder, and the placeholder's 0-based column in it.
local function commented_placeholder(at, indent)
  local placeholder = "\1" -- a byte that cannot already be in the comment
  vim.api.nvim_buf_set_lines(0, at, at, false, { indent .. placeholder })
  parse_rows(at, at + 1)
  vim.api.nvim_win_set_cursor(0, { at + 1, 0 })
  vim.cmd.normal("gcc") -- remapped: runs the default `gcc`
  local line = vim.api.nvim_buf_get_lines(0, at, at + 1, false)[1]
  vim.api.nvim_buf_set_lines(0, at, at + 1, false, {})
  local col = assert(line:find(placeholder, 1, true)) - 1
  return line:sub(1, col) .. line:sub(col + 2), col
end

-- Put the cursor at 0-based `col` of 1-based `row` and start inserting there.
local function insert_at(row, col, line)
  vim.api.nvim_win_set_cursor(0, { row, col })
  if col >= #line then
    vim.cmd("startinsert!") -- at the end of the line: append
  else
    vim.cmd("startinsert") -- inside a block comment: insert before the closer
  end
end

-- Add a comment line above / below the current line and start inserting into it.
local function add_comment_line(where)
  return function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local indent = vim.api.nvim_get_current_line():match("^%s*")
    local at = where == "above" and row - 1 or row -- 0-based insertion index
    local line, col = commented_placeholder(at, indent)
    vim.api.nvim_buf_set_lines(0, at, at, false, { line })
    insert_at(at + 1, col, line)
  end
end

-- Append a comment two spaces after the end of the current line and start
-- inserting into it; a blank line is commented at its indent instead.
local function add_comment_eol()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^%s*")
  -- In the current line's place, so the leader suits the language there.
  local comment, col = commented_placeholder(row - 1, indent)
  if line:find("%S") then
    local code = line:match("^(.-)%s*$") .. "  "
    comment, col = code .. comment:sub(#indent + 1), #code + col - #indent
  end
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { comment })
  insert_at(row, col, comment)
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
vim.keymap.set("n", "gcA", add_comment_eol, { desc = "Add comment at end of line" })

-- `{ left, right }` of a commentstring, or nil when it has no right part.
local function block_parts(cs)
  local left, right = (cs or ""):match("^%s*(.-)%s*%%s%s*(.-)%s*$")
  if right and right ~= "" then
    return { left, right }
  end
end

-- 'commentstring' of the innermost language at 0-based (row, col), as native
-- `gc` picks it, for languages nvim-ts-context-commentstring does not know.
local function commentstring_at(row, col)
  local parser = vim.treesitter.get_parser(0, nil, { error = false })
  local tree = parser and parser:language_for_range({ row, col, row, col })
  while tree and tree:parent() do -- the root tree is the buffer's own language
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(tree:lang())) do
      local cs = vim.filetype.get_option(ft, "commentstring")
      if cs ~= "" then
        return cs
      end
    end
    tree = tree:parent()
  end
  return vim.bo.commentstring
end

-- 'operatorfunc' for `gb`: wrap the text between the `[` and `]` marks in a
-- block comment, or unwrap it if it already starts and ends with the markers.
-- Linewise (and blockwise) ranges skip the first line's indent and the last
-- line's trailing whitespace.
function _G.F2dvim_block_comment(kind)
  local s = vim.api.nvim_buf_get_mark(0, "[")
  local e = vim.api.nvim_buf_get_mark(0, "]")
  local sr, er = s[1] - 1, e[1] - 1
  local first = vim.api.nvim_buf_get_lines(0, sr, sr + 1, false)[1]
  local last = vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1]
  local sc, ec -- 0-based, `ec` exclusive
  if kind == "char" then
    sc = math.min(s[2], #first)
    ec = e[2] < #last and e[2] + 1 + vim.str_utf_end(last, e[2] + 1) or #last
  else
    sc = #first:match("^%s*")
    ec = #last:match("^(.-)%s*$")
    if sr == er then
      ec = math.max(ec, sc) -- a blank line
    end
  end

  parse_rows(sr, er + 1)
  local parts = block_parts(
    require("ts_context_commentstring").calculate_commentstring({
      key = "__multiline",
      location = { sr, sc },
    })
  ) or block_parts(commentstring_at(sr, sc))
  if not parts then
    vim.notify("No block comment for this language", vim.log.levels.WARN)
    return
  end
  local left, right = parts[1], parts[2]

  -- Edit only the two ends (the end first, so `sc` stays valid), so the text
  -- in between, and the cursor on it, does not move.
  local text = table.concat(vim.api.nvim_buf_get_text(0, sr, sc, er, ec, {}), "\n")
  if
    #text >= #left + #right
    and vim.startswith(text, left)
    and vim.endswith(text, right)
  then
    local inner = text:sub(#left + 1, #text - #right)
    local lpad = inner:match("^ ") and 1 or 0
    local rpad = #inner > lpad and inner:match(" $") and 1 or 0
    vim.api.nvim_buf_set_text(0, er, ec - #right - rpad, er, ec, {})
    vim.api.nvim_buf_set_text(0, sr, sc, sr, sc + #left + lpad, {})
  else
    vim.api.nvim_buf_set_text(0, er, ec, er, ec, { " " .. right })
    vim.api.nvim_buf_set_text(0, sr, sc, sr, sc, { left .. " " })
  end
end

local function block_operator()
  vim.o.operatorfunc = "v:lua.F2dvim_block_comment"
  return "g@"
end
vim.keymap.set(
  { "n", "x" },
  "gb",
  block_operator,
  { expr = true, desc = "Toggle block comment" }
)
vim.keymap.set("n", "gbc", function()
  return block_operator() .. "_"
end, { expr = true, desc = "Toggle block comment on line" })
