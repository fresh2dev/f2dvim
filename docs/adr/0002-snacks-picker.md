# Snacks.picker is the only picker

fzf-lua was the picker and `vim.ui.select` handler, while snacks.nvim (already loaded
for its other modules) supplied the `undo` and `projects` pickers fzf-lua lacked. Two
pickers did one job, and fzf-lua needs the `fzf` binary, which a machine running
f2dvim may not have. `Snacks.picker` now does all of it: the config already loads it,
its matcher is pure Lua, and it pins file and grep searches to `rg`. Its `smart` picker
covers what used to take both `<leader>ff` and `<leader>fr`: one list of files with open
buffers and recent files ranked first, and the ranking still favours them as you type.

## Considered Options

- **Keep fzf-lua**: rejected. It is the only one of the three that matches with real
  `fzf`, but that needs the binary, and `FzfLua combine pickers=oldfiles;files` shows
  each recent file twice and drops recency as soon as you type.
- **mini.pick + mini.extra**: rejected. Pure Lua and smaller than Snacks, but its
  preview replaces the list instead of sitting beside it, and a recent-first file
  picker is custom code that only uses recency to break ties.
