vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.diff" },
  { src = "https://github.com/folke/snacks.nvim" },
})

local MiniDiff = require("mini.diff")

MiniDiff.setup({
  view = {
    style = "sign",
    signs = { add = "┃", change = "┃", delete = "_" },
  },
  -- `gh` / `gH` (apply / reset) and the `gh` textobject keep their defaults.
  -- The goto maps are global, so they would shadow diff-mode `]c`; see below.
  mappings = { goto_first = "", goto_prev = "", goto_next = "", goto_last = "" },
  options = { wrap_goto = true },
})

for lhs, direction in pairs({
  ["[C"] = "first",
  ["[c"] = "prev",
  ["]c"] = "next",
  ["]C"] = "last",
}) do
  vim.keymap.set("n", lhs, function()
    if vim.wo.diff and lhs:lower() == lhs then
      vim.cmd.normal({ vim.v.count1 .. lhs, bang = true })
    elseif MiniDiff.get_buf_data(0) then
      MiniDiff.goto_hunk(direction, { n_times = vim.v.count1 })
    end
  end, { desc = "Go to " .. direction .. " hunk" })
end

Snacks.toggle({
  name = "Diff Overlay",
  get = function()
    return (MiniDiff.get_buf_data(0) or {}).overlay == true
  end,
  set = function()
    if MiniDiff.get_buf_data(0) then
      MiniDiff.toggle_overlay(0)
    end
  end,
}):map("<leader>to")
