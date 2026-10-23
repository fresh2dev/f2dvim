vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

Snacks = require("snacks")

--- Run `cmd` in a floating zellij pane inside zellij, else in a Snacks terminal
--- (or `fallback`, such as Snacks.lazygit). Either closes when `cmd` exits.
---@param cmd string[]
---@param fallback? fun()
local function terminal(cmd, fallback)
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
    "zellij", "run", "--floating", "--close-on-exit", "--name", cmd[1],
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

-- In its own zellij pane, fzj needs `--here`; otherwise it opens a second one.
local function sessions()
  terminal(vim.env.ZELLIJ and { "fzj", "--here" } or { "fzj" })
end

--- Pad every line of `text` to the widest. Snacks centres each line of the
--- header on its own width, and the commit hooks strip trailing spaces.
local function block(text)
  local lines = vim.split(text, "\n")
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end
  for i, line in ipairs(lines) do
    lines[i] = line .. (" "):rep(width - vim.api.nvim_strwidth(line))
  end
  return table.concat(lines, "\n")
end

local function key(k, icon, desc, action, enabled)
  return { key = k, icon = icon, desc = desc, action = action, enabled = enabled }
end

-- The Fresh2Dev glasses.
local frame = {
  "╒═════════════════════════════════════════════════════╕",
  "│◦                                                   ◦│",
  "╘╤═════════════════════╤═══════╤═════════════════════╤╛",
  " │                     │       │                   ✦ │",
  " │      F R E S H      │       │        D E V        │",
  " ╰╮                   ╭╯   2   ╰╮                   ╭╯",
  "  ╰───────────────────╯         ╰───────────────────╯",
}
-- The temples, nearest the frame first; shown as the height allows.
local temples = {
  " ╱                                                   ╲",
  "  ╱                                                 ╲",
  "   ╭                                               ╮",
}

local dashboard = {
  enabled = true,
  width = 44,
  preset = {
    keys = {
      key("n", " ", "New file", "<Cmd>enew | startinsert<CR>"),
      { key = "e", action = "<Cmd>enew | startinsert<CR>", hidden = true },
      key("f", " ", "Find files", function()
        Snacks.picker.smart()
      end),
      key("/", " ", "Search", function()
        Snacks.picker.grep()
      end),
      key("\\", " ", "Explore", function()
        require("mini.files").open(nil, false)
      end),
      key("g", " ", "LazyGit", function()
        terminal({ "lazygit" }, Snacks.lazygit)
      end, vim.fn.executable("lazygit") == 1),
      key("B", " ", "Beads", function()
        terminal({ "bv" })
      end, vim.fn.executable("bv") == 1),
      key("J", " ", "Just", function()
        terminal({ "just" })
      end, vim.fn.executable("just") == 1),
      key(
        "s",
        " ",
        "Sessions",
        sessions,
        vim.env.ZELLIJ ~= nil and vim.fn.executable("fzj") == 1
      ),
      {
        key = "0",
        action = sessions,
        hidden = true,
        enabled = vim.env.ZELLIJ ~= nil and vim.fn.executable("fzj") == 1,
      },
      -- The f2dvim package replaces vim.pack.update with a warning.
      key("u", " ", "Update plugins", function()
        vim.pack.update()
      end, vim.env.NVIM_APPNAME ~= "f2dvim"),
      -- Snacks has already closed a floating dashboard before running an action.
      -- One that owns its window (at startup) quits Neovim when no listed buffer
      -- is left, else mini.bufremove deletes it and keeps the window.
      key("q", " ", "Close", function(self)
        if not vim.api.nvim_buf_is_valid(self.buf) then
          return
        end
        local listed = vim.tbl_filter(function(buf)
          return vim.bo[buf].buflisted
        end, vim.api.nvim_list_bufs())
        if #listed == 0 then
          vim.cmd.quitall()
        else
          MiniBufremove.delete(self.buf)
        end
      end),
    },
  },
  sections = {
    -- The keys and the footer come first. The glasses get the rows left over:
    -- the frame only if it fits whole, then the temples one row at a time.
    function(self)
      local keys = #vim.tbl_filter(function(item)
        return not item.hidden and item.enabled ~= false
      end, self.opts.preset.keys)
      -- Keys with a blank row between them, the footer, and the 2 rows of padding
      -- after each of those and after the glasses.
      local spare = self._size.height - (2 * keys + 1) - 3 - 2
      if spare < #frame then
        return
      end
      local rows = {}
      for i = math.min(spare - #frame, #temples), 1, -1 do
        rows[#rows + 1] = temples[i]
      end
      vim.list_extend(rows, frame)
      return { header = block(table.concat(rows, "\n")), padding = 2 }
    end,
    { section = "keys", gap = 1, padding = 2 },
    function()
      local plugins = #vim.tbl_filter(function(path)
        return path:find("/pack/[^/]+/opt/") ~= nil
      end, vim.api.nvim_list_runtime_paths())
      local v = vim.version()
      local ms = math.floor((vim.uv.hrtime() - vim.g.start_hrtime) / 1e6 + 0.5)
      return {
        align = "center",
        padding = 2,
        text = {
          { ("Neovim %d.%d.%d"):format(v.major, v.minor, v.patch), hl = "footer" },
          { "  ·  ", hl = "footer" },
          { ("%d plugins in %d ms"):format(plugins, ms), hl = "footer" },
        },
      }
    end,
  },
}

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
  styles = {
    -- Only the floating dashboard (`<leader><Space>`) can have a border.
    dashboard = {
      border = "rounded",
      wo = {
        winhighlight = "Normal:SnacksDashboardNormal,NormalFloat:SnacksDashboardNormal,"
          .. "FloatBorder:SnacksDashboardBorder",
      },
    },
  },
  animate = { enabled = false },
  bigfile = { enabled = true },
  dashboard = dashboard,
  -- Guides only: mini.indentscope draws the current scope.
  indent = { enabled = true, scope = { enabled = false } },
  input = { enabled = true },
  lazygit = {
    enabled = true,
    -- Don't generate a lazygit config (theme, editing in this Neovim); lazygit's
    -- own config applies.
    configure = false,
  },
  notifier = {
    enabled = true,
    timeout = 5000,
    style = "minimal",
  },
  -- Also the `vim.ui.select` handler.
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
  scroll = { enabled = false }, -- Buggy.
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
        width = 0.8,
      },
    },
  },
})

vim.g.snacks_animate = false

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
pick("n", "<leader>fs", "lsp_symbols", "[F]ind [S]ymbols (buffer)")
pick("n", "<leader>fS", "lsp_workspace_symbols", "[F]ind [S]ymbols (workspace)")

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

--- An sRGB hex colour for OKLCH lightness `l`, chroma `c` and hue `h` (degrees).
--- OKLCH is perceptually uniform: every hue at the same `l` and `c` looks equally
--- bright. Out-of-gamut channels are clipped.
local function oklch(l, c, h)
  local a, b = c * math.cos(math.rad(h)), c * math.sin(math.rad(h))
  local l_ = (l + 0.3963377774 * a + 0.2158037573 * b) ^ 3
  local m_ = (l - 0.1055613458 * a - 0.0638541728 * b) ^ 3
  local s_ = (l - 0.0894841775 * a - 1.2914855480 * b) ^ 3
  local hex = "#"
  for _, x in ipairs({
    4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
    -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
    -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_,
  }) do
    x = x <= 0.0031308 and 12.92 * x or 1.055 * x ^ (1 / 2.4) - 0.055
    hex = hex .. ("%02x"):format(math.floor(255 * math.min(math.max(x, 0), 1) + 0.5))
  end
  return hex
end

-- One accent per session, a random hue at fixed lightness and chroma, for the
-- dashboard's banner, icons, keys and border: it tells sessions apart. Set on
-- every open because a colorscheme change resets the groups.
local accent = oklch(0.8, 0.12, vim.uv.random(1):byte() * 360 / 256)

vim.api.nvim_create_autocmd("User", {
  pattern = "SnacksDashboardOpened",
  callback = function()
    for _, group in ipairs({ "Header", "Icon", "Key", "Border" }) do
      vim.api.nvim_set_hl(0, "SnacksDashboard" .. group, { fg = accent })
    end
  end,
})

vim.keymap.set("n", "<leader><Space>", function()
  Snacks.dashboard()
end, { desc = "Dashboard" })

--------------------------------------------------------------------------------
--- Terminals
--------------------------------------------------------------------------------

vim.keymap.set("n", "<leader>`", function()
  Snacks.terminal()
end, { desc = "Toggle Terminal" })

vim.keymap.set("n", "<leader>gg", function()
  terminal({ "lazygit" }, Snacks.lazygit)
end, { desc = "LazyGit" })

vim.keymap.set("n", "<leader>fp", sessions, { desc = "[F]ind [P]roject" })

-- TODO: add commands `:LazyGit [<args>]` `:Just [<args>]`, `:J [<args>]`

-- TODO: *replace* this with a command named `:Just`
vim.keymap.set("n", "<leader>J", function()
  terminal({ "just" })
end, { desc = "[J]ust Command Runner" })
