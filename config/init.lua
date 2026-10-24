-- ============================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
vim.loader.enable()

-- Read by the dashboard footer (plugin/99-snacks.dashboard.lua).
vim.g.start_hrtime = vim.uv.hrtime()

-- Set before any plugin file runs: a mapping binds the leader in effect when made.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- [[ Setting options ]]

vim.o.number = true
-- vim.o.relativenumber = true

vim.o.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Use the system clipboard.
vim.o.clipboard = "unnamedplus"

vim.o.breakindent = true

vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = "yes"

-- Also the CursorHold delay (LSP reference highlights, mini.map).
vim.o.updatetime = 250

-- -- Decrease mapped sequence wait time
-- vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview `:s` live; matches off screen show in a split.
vim.o.inccommand = "split"

vim.o.cursorline = true

vim.o.scrolloff = 10

vim.o.confirm = true

-- Reload file when changed externally (autoread is on by default; this triggers the check)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  desc = "Check timestamps and reload file if changed outside Neovim",
  command = "silent! checktime",
})

-- Jumps (G, gg, %, CTRL-D/U/B/F, H/M/L, etc.) land on the first non-blank of the target line
vim.o.startofline = true

-- Don't redraw during macros and other untyped commands; speeds up large changes
vim.o.lazyredraw = true

-- Don't evaluate modelines; mitigates editor-config injection from untrusted files
vim.o.modeline = false

-- Briefly highlight the matching bracket when the cursor lands on one
vim.o.showmatch = true
vim.o.matchtime = 2

-- NOTE: 'foldcolumn', 'foldlevel' and 'fillchars' are set in plugin/99-ufo.lua

-- Don't auto-open folds on horizontal or jump-block motions (see `:help 'foldopen'`)
vim.opt.foldopen:remove({ "hor", "block" })

-- Most files live in version control; disable writebackup and swapfile
vim.o.writebackup = false
vim.o.swapfile = false

vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4

-- When wrap is on, break lines at word boundaries rather than mid-word
vim.o.linebreak = true

vim.o.wrap = false

vim.o.background = "dark"

vim.o.termguicolors = true

-- Global statusline: mini.statusline and snacks zen expect it.
vim.o.laststatus = 3

vim.o.title = true
vim.o.titlestring = "NVIM: %f"

vim.o.winborder = "rounded"

-- Don't shift `#`-prefixed lines to column 0 (preserves comment indent)
vim.o.cindent = true
vim.opt.cinkeys:remove("0#")

vim.api.nvim_create_autocmd("VimResized", {
  desc = "Auto-resize splits when the host window changes size",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Jump to the last edit position when opening a file",
  callback = function()
    local last = vim.fn.line([['"]])
    if last > 1 and last <= vim.fn.line("$") then
      vim.cmd('normal! g`"')
    end
  end,
})

-- Smarter cursorline: only the active window when not in insert mode
-- https://github.com/mhinz/vim-galore?tab=readme-ov-file#smarter-cursorline
local cursorline_group =
  vim.api.nvim_create_augroup("smarter-cursorline", { clear = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  group = cursorline_group,
  callback = function()
    vim.wo.cursorline = true
  end,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  group = cursorline_group,
  callback = function()
    vim.wo.cursorline = false
  end,
})

-- [[ Basic Keymaps ]]

-- Better up/down for wrapped lines: with no count, move by visual line (`gj`/`gk`),
-- but with a count, jump by logical lines so relative jumps still hit the right target
for _, lhs in ipairs({ "j", "<Down>" }) do
  vim.keymap.set({ "n", "x" }, lhs, function()
    return vim.v.count == 0 and "gj" or "j"
  end, { expr = true, silent = true })
end
for _, lhs in ipairs({ "k", "<Up>" }) do
  vim.keymap.set({ "n", "x" }, lhs, function()
    return vim.v.count == 0 and "gk" or "k"
  end, { expr = true, silent = true })
end

vim.keymap.set("x", "g/", [[<esc>/\%V]], { desc = "Search inside selection" })

-- Exit terminal-insert mode with <C-u> for easier scrollback
vim.keymap.set("t", "<C-u>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

vim.keymap.set("n", "gb", ":ls<CR>:b<Space>", { desc = "List buffers and switch" })

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

-- Linewise paste helper (ported from tpope/vim-unimpaired). Forces the paste to
-- behave as linewise even when the register holds characterwise text, then
-- restores the original register type so subsequent pastes aren't affected.
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

-- Linewise paste (vim-unimpaired style). The list pairs (`[a`, `[b`, `[q`, `[l`,
-- ...) are Neovim defaults.
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

-- -- Navigate treesitter nodes in visual mode (BUILTIN NEOVIM >= 0.12)
-- vim.keymap.set({ 'x' }, '[n', function()
--   require 'vim.treesitter._select'.select_prev(vim.v.count1)
-- end, { desc = 'Select previous treesitter node' })
-- vim.keymap.set({ 'x' }, ']n', function()
--   require 'vim.treesitter._select'.select_next(vim.v.count1)
-- end, { desc = 'Select next treesitter node' })

-- Open the current buffer in a new tab (like <C-w>T but preserves the original window)
vim.keymap.set("n", "<C-w>t", "<Cmd>tab split<CR>", { desc = "Buffer in new tab" })

-- NOTE: "saner" n/N (always forward / always backward) lives in
-- plugin/99-hlslens.lua because hlslens must wrap the same keys.

-- "Saner" command-line history: <C-n>/<C-p> traverse history when the wildmenu isn't open
-- https://github.com/mhinz/vim-galore?tab=readme-ov-file#saner-command-line-history
vim.keymap.set("c", "<C-n>", function()
  return vim.fn.wildmenumode() == 1 and "<C-n>" or "<Down>"
end, { expr = true, desc = "Next in history (or wildmenu)" })
vim.keymap.set("c", "<C-p>", function()
  return vim.fn.wildmenumode() == 1 and "<C-p>" or "<Up>"
end, { expr = true, desc = "Previous in history (or wildmenu)" })

vim.keymap.set("x", "p", "pgvy", { desc = "Paste over selection (keep register)" })

vim.keymap.set("n", "gp", "`[v`]", { desc = "Select last pasted text" })

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

-- Sticky yank: `y`/`Y` leave the cursor and the view where they were instead
-- of jumping to the start of the yanked text (`ygg` no longer scrolls away).
-- The operator only runs after the mapping returns, so the view is recorded
-- here and restored from TextYankPost. The record belongs to that one yank: it
-- is dropped once the command is over (yanked or cancelled with <Esc>), so
-- yanks that don't come through these keys (`:yank`, a plugin's `normal! y`)
-- are left alone.
-- Inspired by: https://nanotipsforvim.prose.sh/sticky-yank
do
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
end

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

vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Diagnostics; see `:help vim.diagnostic.Opts`.
vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({
        bufnr = bufnr,
        scope = "cursor",
        focus = false,
      })
    end,
  },
})

-- Exit terminal mode with a double <Esc> (the builtin is <C-\><C-n>)
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- NOTE: <C-hjkl> window navigation and <C-Arrow> window resizing are provided
-- by mini.basics (plugin/99-mini.basics.lua).

-- [[ Basic Autocommands ]]

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- ============================================================
-- SECTION 2: PLUGIN MANAGER HOOKS
-- vim.pack build hooks
-- ============================================================
do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ""
      local stdout = result.stdout or ""
      local output = stderr ~= "" and stderr or stdout
      if output == "" then
        output = "No output from build command."
      end
      vim.notify(
        ("Build failed for %s:\n%s"):format(name, output),
        vim.log.levels.ERROR
      )
    end
  end

  -- Build steps after a plugin is installed or updated (`:help vim.pack-events`).
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= "install" and kind ~= "update" then
        return
      end

      -- if name == 'LuaSnip' then
      --   if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then
      --     run_build(name, { 'make', 'install_jsregexp' }, ev.data.path)
      --   end
      --   return
      -- end

      if name == "nvim-treesitter" then
        if not ev.data.active then
          vim.cmd.packadd("nvim-treesitter")
        end
        vim.cmd("TSUpdate")
        return
      end
    end,
  })
end
