vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.map" },
})

local MiniMap = require("mini.map")
MiniMap.setup({
  width = 5,
  integrations = {
    MiniMap.gen_integration.builtin_search(),
    MiniMap.gen_integration.diff(),
    -- MiniMap.gen_integration.diagnostic(),
  },
  symbols = {
    encode = MiniMap.gen_encode_symbols.dot("4x2"),
  },
})

-- open()/close() only on a state change: open() on an open map re-renders it
local function set_map_open(want)
  local win = MiniMap.current.win_data[vim.api.nvim_get_current_tabpage()]
  if want ~= (win ~= nil and vim.api.nvim_win_is_valid(win)) then
    (want and MiniMap.open or MiniMap.close)()
  end
end

-- Only in file buffers: help, quickfix, terminals and the dashboard all set 'buftype'.
local function file_buffer()
  return vim.bo.buftype == ""
end

vim.api.nvim_create_autocmd({ "WinEnter", "FileType" }, {
  callback = function()
    set_map_open(file_buffer())
  end,
})

-- Skip floats: completion/hover popups close constantly while typing
vim.api.nvim_create_autocmd("WinClosed", {
  callback = function(ev)
    local win = tonumber(ev.match)
    if vim.api.nvim_win_get_config(win).relative == "" then
      MiniMap.refresh()
    end
  end,
})

-- Hide the map while the cursor is near the right edge, where the map covers text.
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  callback = function()
    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local width = vim.api.nvim_win_get_width(0)
    set_map_open(file_buffer() and width - col >= 20)
  end,
})
