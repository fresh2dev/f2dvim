-- Named after tpope/vim-unimpaired, whose `[p` and `[e` families these port; that
-- plugin is not installed. The list pairs (`[a`, `[b`, `[q`, `[l`, ...) are Neovim
-- defaults.
vim.pack.add({
  { src = "https://github.com/tpope/vim-repeat" },
})

-- Wrap a mapping so `.` replays the whole mapping (register and count included).
local function repeatable(lhs, fn)
  lhs = vim.keycode(lhs)
  return function()
    local reg, count = vim.v.register, vim.v.count
    fn(reg, count)
    vim.fn["repeat#setreg"](lhs, reg)
    vim.fn["repeat#set"](lhs, count) -- after the last change: keyed to b:changedtick
  end
end

-- Linewise paste helper. Forces the paste to behave as linewise even when the
-- register holds characterwise text, then restores the original register type so
-- subsequent pastes aren't affected.
local function putline(how)
  local body = vim.fn.getreg(vim.v.register)
  local rtype = vim.fn.getregtype(vim.v.register)
  if rtype == "V" then
    vim.cmd('normal! "' .. vim.v.register .. how)
  else
    vim.fn.setreg(vim.v.register, body, "l")
    vim.cmd('normal! "' .. vim.v.register .. how)
    vim.fn.setreg(vim.v.register, body, rtype)
  end
end

-- Builds the callback for the [p/]p family. With `post_op`, the count is folded
-- into the paste and `post_op` (a normal-mode command like `>']`) operates on
-- the just-pasted region.
local function put(lhs, how, post_op)
  return repeatable(lhs, function(_, count)
    putline((post_op and tostring(math.max(count, 1)) or "") .. how)
    if post_op then
      vim.cmd("normal! " .. post_op)
    end
  end)
end

for _, m in ipairs({
  { "[p", put("[p", "[p"), "Paste linewise above" },
  { "]p", put("]p", "]p"), "Paste linewise below" },
  { "[P", put("[P", "[p"), "Paste linewise above" },
  { "]P", put("]P", "]p"), "Paste linewise below" },
  { ">P", put(">P", "[p", ">']"), "Paste linewise above, then shift right" },
  { ">p", put(">p", "]p", ">']"), "Paste linewise below, then shift right" },
  { "<P", put("<P", "[p", "<']"), "Paste linewise above, then shift left" },
  { "<p", put("<p", "]p", "<']"), "Paste linewise below, then shift left" },
  { "=P", put("=P", "[p", "=']"), "Paste linewise above, then reindent" },
  { "=p", put("=p", "]p", "=']"), "Paste linewise below, then reindent" },
}) do
  vim.keymap.set("n", m[1], m[2], { silent = true, desc = m[3] })
end

-- Move (i.e., "exchange") current line up / down (accepts a count)
-- https://github.com/mhinz/vim-galore?tab=readme-ov-file#quickly-move-current-line
vim.keymap.set(
  "n",
  "[e",
  repeatable("[e", function(_, count)
    vim.cmd("move -1-" .. math.max(count, 1))
  end),
  { desc = "Move line(s) up" }
)
vim.keymap.set(
  "n",
  "]e",
  repeatable("]e", function(_, count)
    vim.cmd("move +" .. math.max(count, 1))
  end),
  { desc = "Move line(s) down" }
)
-- Visual mode moves the selected lines as a block and reselects them. The
-- `'<`/`'>` marks are only set on leaving Visual mode, so exit first, `:move`
-- relative to those marks, then `gv` to reselect the (now shifted) block.
local function move_selection(direction)
  return function()
    local count = vim.v.count1
    vim.cmd("normal! \27") -- <Esc>: leave Visual mode, set '< and '>
    if direction == "up" then
      vim.cmd(("'<,'>move '<-%d"):format(count + 1))
    else
      vim.cmd(("'<,'>move '>+%d"):format(count))
    end
    vim.cmd("normal! gv")
  end
end
vim.keymap.set("x", "[e", move_selection("up"), { desc = "Move selection up" })
vim.keymap.set("x", "]e", move_selection("down"), { desc = "Move selection down" })
