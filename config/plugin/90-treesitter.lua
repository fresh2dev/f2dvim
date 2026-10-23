vim.pack.add({
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    version = "main",
  },
})

-- Installed up front; any other parser is installed on first use (FileType below).
local parsers = {
  "bash",
  "c",
  "c_sharp",
  "css",
  "csv",
  "diff",
  "dockerfile",
  "git_config",
  "git_rebase",
  "gitattributes",
  -- "gitcommit",  -- Slow to compile on older versions of glibc
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gotmpl",
  "helm",
  "html",
  "jinja",
  "json",
  "just",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "powershell",
  "python",
  "r",
  "sql",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}
require("nvim-treesitter").install(parsers)

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  -- Check if a parser exists and load it
  if not vim.treesitter.language.add(language) then
    return
  end
  vim.treesitter.start(buf, language)

  -- Enable treesitter based folds
  -- For more info on folds see `:help folds`
  -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  -- vim.wo.foldmethod = 'expr'

  -- Without an indents query, Neovim's own 'indentexpr' stays.
  local has_indent_query = vim.treesitter.query.get(language, "indents") ~= nil

  if has_indent_query then
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

local available_parsers = require("nvim-treesitter").get_available()
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local buf, filetype = args.buf, args.match

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then
      return
    end

    local installed_parsers = require("nvim-treesitter").get_installed("parsers")

    if vim.tbl_contains(installed_parsers, language) then
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      require("nvim-treesitter").install(language):await(function()
        treesitter_try_attach(buf, language)
      end)
    else
      -- The parser can exist without nvim-treesitter (Neovim bundles some).
      treesitter_try_attach(buf, language)
    end
  end,
})
