-- The Snacks dashboard. `Snacks.setup` is in 99-snacks.lua; see there.
vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

Snacks = require("snacks")
local util = require("util")

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

-- Overrides the global `winborder` for the floating dashboard (`<leader><Space>`).
Snacks.config.styles.dashboard = { border = "none" }

Snacks.config.dashboard = {
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
        Snacks.lazygit()
      end, vim.fn.executable("lazygit") == 1),
      key("t", "", "Terminal", util.float_terminal),
      key(
        "s",
        " ",
        "Sessions",
        util.sessions,
        vim.env.ZELLIJ ~= nil and vim.fn.executable("fzj") == 1
      ),
      {
        key = "0",
        action = util.sessions,
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

vim.keymap.set("n", "<leader><Space>", function()
  Snacks.dashboard()
end, { desc = "Dashboard" })
