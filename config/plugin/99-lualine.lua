vim.pack.add({
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
  { src = "https://github.com/nvim-mini/mini.icons" },
})

local function wordcount()
  return tostring(vim.fn.wordcount().words) .. " words"
end

local function readingtime()
  return tostring(math.ceil(vim.fn.wordcount().words / 200.0)) .. " min"
end

local function is_markdown()
  return vim.bo.filetype == "markdown" or vim.bo.filetype == "asciidoc"
end

require("lualine").setup({

  options = {
    component_separators = { left = "|", right = "|" },
    section_separators = { left = "", right = "" },
    -- Must agree with `laststatus = 3` in init.lua (snacks zen relies on it)
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {},
    lualine_c = {
      {
        "filename",
        path = 1, -- relative path
      },
    },
    -- lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_x = {
      { wordcount, cond = is_markdown },
      { readingtime, cond = is_markdown },
      -- 'diagnostics',
      { "filetype", colored = true, icon_only = false },
    },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {},
})
