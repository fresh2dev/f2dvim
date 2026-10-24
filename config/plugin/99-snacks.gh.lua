-- Snacks gh: GitHub issue and pull request pickers, through the `gh` CLI.
-- `Snacks.setup` is in 99-snacks.lua; see there. gh needs no setup, so there
-- is no `Snacks.config.gh`.
vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

Snacks = require("snacks")

local function pick(lhs, source, desc, opts)
  vim.keymap.set("n", lhs, function()
    Snacks.picker[source](opts)
  end, { desc = desc })
end

pick("<leader>ghi", "gh_issue", "[G]it[H]ub [I]ssues (open)")
pick("<leader>ghI", "gh_issue", "[G]it[H]ub [I]ssues (all)", { state = "all" })
pick("<leader>ghp", "gh_pr", "[G]it[H]ub [P]ull Requests (open)")
pick("<leader>ghP", "gh_pr", "[G]it[H]ub [P]ull Requests (all)", { state = "all" })
