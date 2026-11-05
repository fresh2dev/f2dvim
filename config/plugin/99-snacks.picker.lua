-- The Snacks picker, also the `vim.ui.select` handler. `Snacks.setup` is in
-- 99-snacks.lua; see there.
vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

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

Snacks.config.picker = {
  enabled = true,
  layout = "vertical",
  layouts = {
    -- The preview (the preset's 3rd window) takes 60% of the picker's height,
    -- not 40%. A table without `[1]` is merged into the preset, not swapped in.
    vertical = { layout = { [3] = { height = 0.6 } } },
  },
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
}

local function pick(mode, lhs, source, desc, opts)
  vim.keymap.set(mode, lhs, function()
    Snacks.picker[source](opts)
  end, { desc = desc })
end

pick("n", "<leader>F", "resume", "[F]ind: Resume Last Picker")
pick("n", "<leader>fa", "pickers", "[F]ind [A]ll Pickers")
pick("n", "<leader>ff", "smart", "[F]ind [F]iles (recent first)")
pick("n", "<leader>fF", "files", "[F]ind [F]iles (incl. ignored)", { ignored = true })
pick("n", "<leader>f/", "grep", "[F]ind by Grep")
pick("n", "<leader>f?", "grep", "[F]ind by Grep (incl. ignored)", { ignored = true })
pick("x", "<leader>f/", "grep_word", "[F]ind Selection by Grep")
pick("n", "<leader>fg", "git_status", "[F]ind [G]it Status")
pick("n", "<leader>fG", "git_diff", "[F]ind [G]it Diff (hunks)")
pick("n", "gl", "lines", "[G]oto [L]ines in Buffer")
-- pick("n", "<leader>fL", "grep_buffers", "[F]ind [L]ines in Open Buffers")
pick("n", "<leader>fb", "buffers", "[F]ind [B]uffers")
pick("n", "<leader>fh", "help", "[F]ind [H]elp")
pick("n", "<leader>fk", "keymaps", "[F]ind [K]eymaps")
pick("n", "<leader>fc", "commands", "[F]ind [C]ommands")
pick("n", "<leader>fC", "command_history", "[F]ind [C]ommands (history)")
pick("n", '<leader>f"', "registers", "[F]ind Registers")
pick("n", "<leader>fy", "cliphist", "[F]ind [Y]ank History (cliphist)")
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
pick("n", "<leader>fs", "lsp_symbols", "[F]ind [S]ymbols (buffer)")
pick("n", "<leader>fS", "lsp_workspace_symbols", "[F]ind [S]ymbols (workspace)")
