vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

-- TODO: deleteme
Snacks = require("snacks")

-- Shared by the picker's input and list windows. The `<a-*>` defaults are
-- unbound because this config maps no Alt keys; their actions are not rebound.
local picker_keys = {
  ["<c-o>"] = { "edit_split", mode = { "i", "n" } },
  ["<c-s>"] = false,
  ["<c-/>"] = { "toggle_preview", mode = { "i", "n" } },
  -- What many terminals send for <c-/>.
  ["<c-_>"] = { "toggle_preview", mode = { "i", "n" } },
  ["<S-Down>"] = { "preview_scroll_down", mode = { "i", "n" } },
  ["<S-Up>"] = { "preview_scroll_up", mode = { "i", "n" } },
  ["<a-d>"] = false,
  ["<a-f>"] = false,
  ["<a-h>"] = false,
  ["<a-i>"] = false,
  ["<a-m>"] = false,
  ["<a-p>"] = false,
  ["<a-r>"] = false,
  ["<a-w>"] = false,
}

Snacks.setup({
  animate = { enabled = false },
  bigfile = { enabled = true },
  dashboard = { enabled = false },
  -- Guides only: mini.indentscope draws the current scope.
  indent = { enabled = true, scope = { enabled = false } },
  input = { enabled = true },
  lazygit = {
    enabled = true,
    -- automatically configure lazygit to use the current colorscheme
    -- and integrate edit with the current neovim instance
    configure = false,
  },
  notifier = {
    enabled = true,
    timeout = 5000,
    style = "minimal", -- 'compact', 'fancy', 'minimal'
  },
  -- The picker for everything, and the `vim.ui.select` handler.
  picker = {
    enabled = true,
    layout = "vertical",
    sources = {
      -- `smart` gets these too: its files finder inherits the `files` source.
      files = { cmd = "rg", hidden = true, follow = true },
      grep = { hidden = true, follow = true },
      grep_word = { hidden = true, follow = true },
      smart = { filter = { cwd = true } },
    },
    win = {
      input = {
        keys = vim.tbl_extend("force", picker_keys, {
          ["<F1>"] = { "toggle_help_input", mode = { "i", "n" } },
          -- close the picker on ESC instead of going to normal mode
          ["<Esc>"] = { "close", mode = { "n", "i" } },
        }),
      },
      list = {
        keys = vim.tbl_extend("force", picker_keys, {
          ["<F1>"] = "toggle_help_list",
        }),
      },
    },
  },
  quickfile = { enabled = false }, -- Doesn't make much of a difference.
  scratch = { enabled = false },
  scroll = { enabled = false }, -- Still buggy.
  statuscolumn = { enabled = true },
  terminal = { enabled = true },
  words = { enabled = true },
  zen = {
    enabled = true,
    toggles = {
      dim = false,
      git_signs = false,
      mini_diff_signs = false,
      diagnostics = false,
      inlay_hints = false,
    },
    show = {
      statusline = true, -- can only be shown when using the global statusline
      tabline = false,
    },
    win = {
      style = "zen",
      backdrop = { transparent = false, blend = 0 },
      width = 0.8,
    },
    zoom = {
      toggles = {},
      show = {
        statusline = true,
        tabline = true,
      },
      win = {
        style = "zen",
        backdrop = { transparent = false, blend = 0 },
        width = 0.8, -- full width
      },
    },
  },
})

vim.g.snacks_animate = false

-- Create some toggle mappings
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>ts")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>tw")
-- Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>tL'
Snacks.toggle.diagnostics():map("<leader>td")
-- Snacks.toggle.line_number():map '<leader>tl'
-- Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>tc'
-- Snacks.toggle.treesitter():map '<leader>tT'
-- Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>tb'
Snacks.toggle.inlay_hints():map("<leader>th")
Snacks.toggle.indent():map("<leader>ti")
-- Snacks.toggle.dim():map("<leader>tD")

-- vim.keymap.set({ 'n', 'x' }, '<leader>gB', Snacks.gitbrowse, { desc = "Git Browse" })
--------------------------------------------------------------------------------
--- Pickers
--------------------------------------------------------------------------------

local function pick(mode, lhs, source, desc, opts)
  vim.keymap.set(mode, lhs, function()
    Snacks.picker[source](opts)
  end, { desc = desc })
end

pick("n", "<leader>F", "resume", "[F]ind: Resume Last Picker")
pick("n", "<leader>fa", "pickers", "[F]ind [A]ll Pickers")
pick("n", "<leader>ff", "smart", "[F]ind [F]iles (recent first)")
pick("n", "<leader>fF", "files", "[F]ind [F]iles (incl. ignored)", { ignored = true })
pick("n", "<leader>fg", "grep", "[F]ind by [G]rep")
pick("n", "<leader>fG", "grep", "[F]ind by [G]rep (incl. ignored)", {
  ignored = true,
})
pick("x", "<leader>fg", "grep_word", "[F]ind Selection by [G]rep")
pick({ "n", "x" }, "<leader>fw", "grep_word", "[F]ind [W]ord by Grep")
pick("n", "gl", "lines", "[G]oto [L]ines in Buffer")
-- pick("n", "<leader>fL", "grep_buffers", "[F]ind [L]ines in Open Buffers")
pick("n", "<leader>fb", "buffers", "[F]ind [B]uffers")
pick("n", "<leader>fh", "help", "[F]ind [H]elp")
pick("n", "<leader>fk", "keymaps", "[F]ind [K]eymaps")
pick("n", "<leader>fc", "commands", "[F]ind [C]ommands")
pick("n", "<leader>fC", "command_history", "[F]ind [C]ommands (history)")
pick("n", "<leader>f/", "search_history", "[F]ind Search History")
pick("n", '<leader>f"', "registers", "[F]ind Registers")
pick("n", "<leader>fj", "jumps", "[F]ind [J]umps")
pick("n", "<leader>f<C-o>", "jumps", "[F]ind [J]umps")
pick("n", "<leader>fm", "marks", "[F]ind [M]arks")
pick("n", "<leader>fd", "diagnostics_buffer", "[F]ind [D]iagnostics (buffer)")
pick("n", "<leader>fD", "diagnostics", "[F]ind [D]iagnostics (workspace)")
pick("n", "<leader>fq", "qflist", "[F]ind in [Q]uickfix")
pick("n", "<leader>fn", "notifications", "[F]ind [N]otifications")
-- Source registered by todo-comments.nvim.
pick("n", "<leader>ft", "todo_comments", "[F]ind [T]odo Comments")
pick("n", "<leader>fu", "undo", "[F]ind [U]ndo History")
pick("n", "U", "undo", "Undotree")
pick("n", "gs", "lsp_symbols", "Document [S]ymbols")
pick("n", "gS", "lsp_workspace_symbols", "Workspace [S]ymbols")

-- Make it easier to get out of terminal mode using Ctrl-w
vim.keymap.set("t", "<C-w>", "<C-\\><C-n><C-w>", { desc = "Window Navigation" })

vim.keymap.set("n", "<leader>tz", function()
  Snacks.zen.zoom()
  vim.cmd("setlocal nonumber")
end, { desc = "[T]oggle [Z]oom" })

vim.keymap.set("n", "gz", function()
  Snacks.zen.zoom()
  vim.cmd("setlocal nonumber")
end, { desc = "[G]o [Z]oom" })

vim.keymap.set("n", "<leader>tZ", function()
  Snacks.zen.zen()
  vim.cmd("setlocal nonumber")
end, { desc = "[T]oggle [Z]en-Mode" })

vim.keymap.set("n", "gZ", function()
  Snacks.zen.zen()
  vim.cmd("setlocal nonumber")
end, { desc = "[G]o [Z]en" })

--------------------------------------------------------------------------------
--- Terminals
--------------------------------------------------------------------------------

vim.keymap.set("n", "<leader>`", function()
  Snacks.terminal()
end, { desc = "Toggle Terminal" })

vim.keymap.set("n", "<leader>lg", function()
  Snacks.lazygit()
end, { desc = "[L]azy[G]it" })

vim.keymap.set("n", "<leader>ghd", function()
  Snacks.terminal({ "hunk", "diff" })
end, { desc = "[H]unk [D]iff" })

vim.keymap.set("n", "<leader>J", function()
  Snacks.terminal({ "just" }, { auto_close = false })
end, { desc = "[J]ust Command Runner" })

-- # TODO: add commands `:LazyGit [<args>]` `:HunkDiff [<args>]` `:HunkShow [<args>]` `:Just [<args>]`, `:J [<args>]`
-- # TODO: somewhat feature parity with Zed configs
