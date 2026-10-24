vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.statusline" },
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

local statusline = require("mini.statusline")

-- Draws the global statusline (`laststatus = 3` in init.lua; snacks zen relies on it),
-- so the inactive content is never shown and keeps its default.
statusline.setup({
  content = {
    active = function()
      local mode, mode_hl = statusline.section_mode({})
      local info = {}
      if is_markdown() then
        table.insert(info, wordcount())
        table.insert(info, readingtime())
      end
      -- The short form is the filetype and its icon alone
      table.insert(info, statusline.section_fileinfo({ trunc_width = math.huge }))

      return statusline.combine_groups({
        { hl = mode_hl, strings = { mode:upper() } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { "%f%m%r" } },
        "%=",
        -- Same plain background as the filename, as lualine drew it
        { hl = "MiniStatuslineFilename", strings = { table.concat(info, " | ") } },
        { hl = "MiniStatuslineDevinfo", strings = { "%P" } },
        { hl = mode_hl, strings = { "%3l:%-2v" } },
      })
    end,
  },
})
