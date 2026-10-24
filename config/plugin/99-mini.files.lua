vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.files" },
  { src = "https://github.com/nvim-mini/mini.icons" },
  { src = "https://github.com/folke/snacks.nvim" },
})

local MiniFiles = require("mini.files")
MiniFiles.setup({
  content = {
    filter = nil,
    prefix = nil,
    sort = nil,
  },

  -- Explorer-buffer mappings; `''` creates none.
  mappings = {
    close = "q",
    go_in = "L",
    go_in_plus = "<CR>",
    go_out = "<BS>",
    go_out_plus = "",
    mark_goto = "'",
    mark_set = "M",
    reset = "<F5>",
    reveal_cwd = "@",
    show_help = "g?",
    synchronize = "<leader>w",
    trim_left = "<",
    trim_right = ">",
  },

  options = {
    permanent_delete = true,
    use_as_default_explorer = true,
  },

  windows = {
    max_number = math.huge,
    preview = true,
    width_focus = 50,
    width_nofocus = 15,
    width_preview = 25,
  },
})

local map_split = function(buf_id, lhs, direction)
  local rhs = function()
    local cur_target = MiniFiles.get_explorer_state().target_window
    local new_target = vim.api.nvim_win_call(cur_target, function()
      vim.cmd(direction .. " split")
      return vim.api.nvim_get_current_win()
    end)

    MiniFiles.set_target_window(new_target)

    MiniFiles.go_in({ close_on_file = true })
  end

  local desc = "Split " .. direction
  vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  callback = function(args)
    local buf_id = args.data.buf_id
    map_split(buf_id, "<C-o>", "belowright horizontal")
    map_split(buf_id, "<C-v>", "belowright vertical")
  end,
})

-- Let language servers update imports when a file is renamed or moved here.
vim.api.nvim_create_autocmd("User", {
  pattern = { "MiniFilesActionRename", "MiniFilesActionMove" },
  callback = function(args)
    Snacks.rename.on_rename_file(args.data.from, args.data.to)
  end,
})

vim.keymap.set("n", "\\", function()
  if not MiniFiles.close() then
    MiniFiles.open(nil, false)
  end
end, { desc = "Show File Explorer" })

vim.keymap.set("n", "|", function()
  if not MiniFiles.close() then
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
    MiniFiles.reveal_cwd()
  end
end, { desc = "Show File Explorer (at current file)" })
