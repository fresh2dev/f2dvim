vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.surround" },
})

require("mini.surround").setup({
  custom_surroundings = {
    -- Surround in triple backticks (markdown code block)
    c = { input = { "```\n().-()\n```" }, output = { left = "```\n", right = "\n```" } },
  },

  highlight_duration = 500,

  -- Map as is done in tpope/vim-surround
  mappings = {
    add = "ys",
    delete = "ds",
    find = "",
    find_left = "",
    highlight = "",
    replace = "cs",
    update_n_lines = "",

    suffix_last = "",
    suffix_next = "",
  },

  -- Number of lines within which surrounding is searched
  n_lines = 25,

  respect_selection_type = false,

  search_method = "cover",

  silent = false,
})

-- Visual `S` replaces visual `ys`. It must leave Visual mode with `<Esc>` before
-- calling `MiniSurround.add("visual")`, not be a Lua callback: leaving Visual mode
-- is what updates the `'<`/`'>` marks it reads, and a callback still in Visual mode
-- reads the previous selection's marks (possibly out of range). `<Esc>` rather
-- than `:<C-u>`, which would move the cursor to the start of the selection.
vim.keymap.del("x", "ys")
vim.keymap.set(
  "x",
  "S",
  [[<Esc><Cmd>lua MiniSurround.add("visual")<CR>]],
  { silent = true, desc = "Surround selection" }
)

-- Every surround operation leaves the cursor on the text it was on. `ds`/`cs` and
-- visual `S` run with the cursor still in place; `.` keeps it via `99-repeat.lua`.
-- `ys` is an operator, and `g@` moves the cursor to the start of the motion before
-- `MiniSurround.add` runs, so the `ys` mapping records the cursor first.
local util = require("util")
local restore_ys -- set by `ys`, used by the `MiniSurround.add` it leads to
for _, name in ipairs({ "add", "delete", "replace" }) do
  local fn = MiniSurround[name]
  MiniSurround[name] = function(...)
    local args, restore = { ... }, nil
    if name == "add" then
      restore, restore_ys = restore_ys, nil
    end
    util.keep_cursor(function()
      fn(unpack(args))
    end, restore)
  end
end
local ys = vim.fn.maparg("ys", "n", false, true).callback
-- shortcut: a cancelled `ys<Esc>` leaves one unused extmark in the buffer.
vim.keymap.set("n", "ys", function()
  restore_ys = util.mark_cursor()
  return ys()
end, { expr = true, desc = "Add surrounding (keep cursor)" })

vim.keymap.set("n", "yss", "ys_", { remap = true, desc = "Surround line" })
