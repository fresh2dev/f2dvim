vim.pack.add({
  { src = "https://github.com/MagicDuck/grug-far.nvim" },
})

-- <localleader> is <Space> here, and a buffer-local map that fully matches fires
-- without waiting, so a <localleader> key below must not equal a global <leader>
-- map or prefix (upstream's <localleader>l/q/t/f/p/w/x all would). <localleader>qq
-- deliberately takes over the global "Quit smart". Editing result lines and syncing
-- them back is disabled; replacements go through Replace or Apply Next/Prev.
require("grug-far").setup({
  transient = true,
  windowCreationCommand = "botright split",
  openTargetWindow = { preferredLocation = "above" },
  keymaps = {
    replace = { n = "<localleader>R" },
    applyNext = { n = "<localleader>j" },
    applyPrev = { n = "<localleader>k" },
    qflist = { n = "<C-q>" },
    close = { n = "<localleader>qq" },
    historyOpen = { n = "<localleader>h" },
    historyAdd = { n = "<localleader>H" },
    refresh = { n = "<F5>" },
    abort = { n = "<localleader>A" },
    toggleShowCommand = { n = "<localleader>c" },
    previewLocation = { n = "K" },
    gotoLocation = { n = "<Enter>" },
    pickHistoryEntry = { n = "<Enter>" },
    help = { n = "g?" },
    openLocation = false,
    openNextLocation = false,
    openPrevLocation = false,
    syncLocations = false,
    syncLine = false,
    syncNext = false,
    syncPrev = false,
    syncFile = false,
    swapEngine = false,
    swapReplacementInterpreter = false,
  },
})

-- The selection fills Search, so start in Replace. A fixed `startCursorRow` would
-- miss the input when the selection spans several lines.
local function open_with_selection(opts)
  local inst = require("grug-far").with_visual_selection(opts)
  inst:when_ready(function()
    inst:goto_input("replacement")
  end)
end

vim.keymap.set("n", "<leader>fr", function()
  require("grug-far").open()
end, { desc = "[F]ind and [R]eplace" })

vim.keymap.set("x", "<leader>fr", function()
  open_with_selection()
end, { desc = "[F]ind and [R]eplace Selection" })

vim.keymap.set("n", "<leader>fR", function()
  require("grug-far").open({ windowCreationCommand = "tab split" })
end, { desc = "[F]ind and [R]eplace in New Tab" })

vim.keymap.set("x", "<leader>fR", function()
  open_with_selection({ windowCreationCommand = "tab split" })
end, { desc = "[F]ind and [R]eplace Selection in New Tab" })
