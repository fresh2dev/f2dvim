from bundle import declared_plugins


def test_src_field_and_bare_string_forms() -> None:
    source = """
vim.pack.add({
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons', version = "main" },
})
vim.pack.add({ "https://github.com/folke/lazydev.nvim" })
"""
    assert declared_plugins([source]) == {
        "fzf-lua": "https://github.com/ibhagwan/fzf-lua",
        "nvim-web-devicons": "https://github.com/nvim-tree/nvim-web-devicons",
        "lazydev.nvim": "https://github.com/folke/lazydev.nvim",
    }


def test_commented_out_declarations_are_ignored() -> None:
    source = """
-- vim.pack.add({
--   { src = "https://github.com/fresh2dev/zellij-agent-pane" },
-- })
--[[
vim.pack.add({ "https://github.com/old/plugin" })
]]
-- fix: https://github.com/tpope/vim-eunuch/issues/95
vim.pack.add({ "https://github.com/tpope/vim-eunuch" }) -- "https://github.com/x/y"
"""
    assert declared_plugins([source]) == {
        "vim-eunuch": "https://github.com/tpope/vim-eunuch",
    }


def test_name_drops_git_suffix_and_merges_files() -> None:
    sources = [
        'vim.pack.add({ "https://github.com/nvim-tree/nvim-web-devicons.git" })',
        'vim.pack.add({ "https://github.com/nvim-tree/nvim-web-devicons" })',
    ]
    assert list(declared_plugins(sources)) == ["nvim-web-devicons"]
