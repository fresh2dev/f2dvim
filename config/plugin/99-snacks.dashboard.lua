-- The Snacks dashboard. `Snacks.setup` is in 99-snacks.lua; see there.
vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
  { src = "https://github.com/nvim-mini/mini.bufremove" },
})

Snacks = require("snacks")

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
-- Snacks centres each header line on its own width, and the commit hooks strip
-- trailing spaces, so pad every line to the first (widest) one.
for i, line in ipairs(frame) do
  frame[i] = line
    .. (" "):rep(vim.api.nvim_strwidth(frame[1]) - vim.api.nvim_strwidth(line))
end
local header = table.concat(frame, "\n")

-- Overrides the global `winborder` for the floating dashboard (`<leader><Space>`).
Snacks.config.styles.dashboard = { border = "none" }

Snacks.config.dashboard = {
  enabled = true,
  width = 44,
  preset = {
    keys = {
      key("f", " ", "Find files", ":lua Snacks.picker.smart()"),
      key("/", " ", "Search", ":lua Snacks.picker.grep()"),
      key("\\", " ", "Explore", ":lua require('mini.files').open(nil, false)"),
      key("i", " ", "New file", ":enew | startinsert"),
      key("g", " ", "LazyGit", function()
        Snacks.lazygit()
      end, vim.fn.executable("lazygit") == 1),
      -- The f2dvim package replaces vim.pack.update with a warning.
      key("u", " ", "Update plugins", function()
        vim.pack.update()
      end, vim.env.NVIM_APPNAME ~= "f2dvim"),
      -- Snacks has already closed a floating dashboard before running an action.
      -- One that owns its window (at startup) quits Neovim when no listed buffer
      -- is left, else mini.bufremove deletes it and keeps the window.
      key("q", " ", "Close", function(self)
        if not vim.api.nvim_buf_is_valid(self.buf) then
          return
        elseif #vim.fn.getbufinfo({ buflisted = 1 }) == 0 then
          vim.cmd.quitall()
        else
          require("mini.bufremove").delete(self.buf)
        end
      end),
    },
  },
  sections = {
    -- The glasses only if they fit beside the keys (a blank row between each), the
    -- footer, and the 2 rows of padding after each of those and after the glasses.
    function(self)
      local keys = #vim.tbl_filter(function(item)
        return not item.hidden and item.enabled ~= false
      end, self.opts.preset.keys)
      if self._size.height - (2 * keys + 1) - 3 - 2 >= #frame then
        return { header = header, padding = 2 }
      end
    end,
    { section = "keys", gap = 1, padding = 2 },
    function()
      local plugins = #vim.tbl_filter(function(path)
        return path:find("/pack/[^/]+/opt/") ~= nil
      end, vim.api.nvim_list_runtime_paths())
      local v = vim.version()
      local ms = math.floor((vim.uv.hrtime() - vim.g.start_hrtime) / 1e6 + 0.5)
      local text = "Neovim %d.%d.%d  ·  %d plugins in %d ms"
      return {
        align = "center",
        padding = 2,
        text = { text:format(v.major, v.minor, v.patch, plugins, ms), hl = "footer" },
      }
    end,
  },
}

vim.keymap.set("n", "<leader><Space>", function()
  Snacks.dashboard()
end, { desc = "Dashboard" })
