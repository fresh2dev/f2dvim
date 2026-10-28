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

-- [[ Options ]]

-- Interface
vim.o.number = true
-- vim.o.relativenumber = true

vim.o.signcolumn = "yes"

vim.o.cursorline = true

vim.o.scrolloff = 10

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Global statusline: mini.statusline and snacks zen expect it.
vim.o.laststatus = 3

-- Numbered tabs, centred; shown once there is a second tab.
vim.o.tabline = "%!v:lua.require'util'.tabline()"

vim.o.title = true
vim.o.titlestring = "NVIM: %f"

vim.o.background = "dark"

vim.o.termguicolors = true

vim.o.winborder = "rounded"

vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Briefly highlight the matching bracket when the cursor lands on one
vim.o.showmatch = true
vim.o.matchtime = 2

-- Don't redraw during macros and other untyped commands; speeds up large changes
vim.o.lazyredraw = true

vim.o.wrap = false

-- When wrap is on, break lines at word boundaries rather than mid-word
vim.o.linebreak = true

vim.o.breakindent = true

-- Input and timing
vim.o.mouse = "a"

-- Use the system clipboard.
vim.o.clipboard = "unnamedplus"

-- Also the CursorHold delay (LSP reference highlights, mini.map).
vim.o.updatetime = 250

-- -- Decrease mapped sequence wait time
-- vim.o.timeoutlen = 300

vim.o.confirm = true

-- Jumps (G, gg, %, CTRL-D/U/B/F, H/M/L, etc.) land on the first non-blank of the target line
vim.o.startofline = true

-- Search
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Preview `:s` live; matches off screen show in a split.
vim.o.inccommand = "split"

-- Indentation
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4

-- Don't shift `#`-prefixed lines to column 0 (preserves comment indent)
vim.o.cindent = true
vim.opt.cinkeys:remove("0#")

-- Windows
vim.o.splitright = true
vim.o.splitbelow = true

-- Folds
-- NOTE: 'foldcolumn', 'foldlevel' and 'fillchars' are set in plugin/99-ufo.lua

-- Don't auto-open folds on horizontal or jump-block motions (see `:help 'foldopen'`)
vim.opt.foldopen:remove({ "hor", "block" })

-- Files
vim.o.undofile = true

-- Most files live in version control; disable writebackup and swapfile
vim.o.writebackup = false
vim.o.swapfile = false

-- Don't evaluate modelines; mitigates editor-config injection from untrusted files
vim.o.modeline = false

-- [[ Diagnostics ]]

-- See `:help vim.diagnostic.Opts`.
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

-- [[ Basic Keymaps ]]

-- Movement
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

-- -- Navigate treesitter nodes in visual mode (BUILTIN NEOVIM >= 0.12)
-- vim.keymap.set({ 'x' }, '[n', function()
--   require 'vim.treesitter._select'.select_prev(vim.v.count1)
-- end, { desc = 'Select previous treesitter node' })
-- vim.keymap.set({ 'x' }, ']n', function()
--   require 'vim.treesitter._select'.select_next(vim.v.count1)
-- end, { desc = 'Select next treesitter node' })

-- Search
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

vim.keymap.set("x", "g/", [[<esc>/\%V]], { desc = "Search inside selection" })

-- NOTE: "saner" n/N (always forward / always backward) lives in
-- plugin/99-hlslens.lua because hlslens must wrap the same keys.

-- Paste
vim.keymap.set("x", "p", "pgvy", { desc = "Paste over selection (keep register)" })

vim.keymap.set("n", "gp", "`[v`]", { desc = "Select last pasted text" })

-- Buffers, windows and tabs
vim.keymap.set("n", "gb", ":ls<CR>:b<Space>", { desc = "List buffers and switch" })

-- Open the current buffer in a new tab (like <C-w>T but preserves the original window)
vim.keymap.set("n", "<C-w>t", "<Cmd>tab split<CR>", { desc = "Buffer in new tab" })

-- NOTE: <C-hjkl> window navigation and <C-Arrow> window resizing are provided
-- by mini.basics (plugin/99-mini.basics.lua).

-- Command line
-- "Saner" command-line history: <C-n>/<C-p> traverse history when the wildmenu isn't open
-- https://github.com/mhinz/vim-galore?tab=readme-ov-file#saner-command-line-history
vim.keymap.set("c", "<C-n>", function()
  return vim.fn.wildmenumode() == 1 and "<C-n>" or "<Down>"
end, { expr = true, desc = "Next in history (or wildmenu)" })
vim.keymap.set("c", "<C-p>", function()
  return vim.fn.wildmenumode() == 1 and "<C-p>" or "<Up>"
end, { expr = true, desc = "Previous in history (or wildmenu)" })

-- Terminal
-- Exit terminal-insert mode with <C-u> for easier scrollback
vim.keymap.set("t", "<C-u>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Exit terminal mode with a double <Esc> (the builtin is <C-\><C-n>)
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- [[ Basic Autocommands ]]

-- Reload file when changed externally (autoread is on by default; this triggers the check)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  desc = "Check timestamps and reload file if changed outside Neovim",
  command = "silent! checktime",
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

vim.api.nvim_create_autocmd("VimResized", {
  desc = "Auto-resize splits when the host window changes size",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
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
