vim.pack.add({
  {
    src = "https://github.com/saghen/blink.cmp",
    version = vim.version.range("1.*"),
  },
})

-- DOCS: https://cmp.saghen.dev
require("blink.cmp").setup({
  keymap = {
    preset = "default",
    -- ['<C-e>'] = { 'hide', 'fallback' },
    -- ['<C-y>'] = { 'select_and_accept', 'fallback' },
    -- ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    -- ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    -- ['<C-p>'] = { 'select_prev', 'fallback' },
    -- ['<C-n>'] = { 'select_next', 'fallback' },
    --
    -- A variant of the super-tab recipe:
    -- https://cmp.saghen.dev/configuration/keymap.html#super-tab
    ["<Tab>"] = {
      function(_cmp)
        if require("blink.cmp.completion.list").get_selected_item() then
          return _cmp.accept()
        end
      end,
      "snippet_forward",
      "fallback",
    },
    ["<CR>"] = { "accept", "fallback" },
  },
  appearance = {
    nerd_font_variant = "mono",
  },
  cmdline = {
    enabled = true,
    keymap = {
      preset = "cmdline",
      ["<down>"] = { "select_next", "fallback" },
      ["<up>"] = { "select_prev", "fallback" },
      ["<left>"] = { "fallback" },
      ["<right>"] = { "fallback" },
    },
    sources = function()
      local type = vim.fn.getcmdtype()
      if type == "/" or type == "?" then
        return { "buffer" }
      end
      if type == ":" or type == "@" then
        return { "cmdline" }
      end
      return {}
    end,
    completion = {
      trigger = {
        show_on_blocked_trigger_characters = {},
        show_on_x_blocked_trigger_characters = {},
      },
      list = {
        selection = {
          preselect = false,
          auto_insert = true,
        },
      },
      menu = { auto_show = false },
      ghost_text = { enabled = true },
    },
  },
  enabled = function()
    local filetype = vim.bo[0].filetype
    if
      filetype == "minifiles"
      or filetype == "snacks_picker_input"
      or filetype == "fugitive"
    then
      return false
    end
    return true
  end,
  completion = {
    keyword = { range = "full" },

    trigger = { show_in_snippet = false },

    list = {
      selection = { preselect = false, auto_insert = false },
    },

    -- Some LSPs still put brackets in their completion text.
    accept = { auto_brackets = { enabled = false } },

    menu = {
      enabled = true,

      auto_show = true,

      -- nvim-cmp style menu
      draw = {
        columns = {
          { "label", "label_description", gap = 1 },
          { "kind_icon", "kind" },
        },
      },
    },

    documentation = {
      auto_show = true,
      auto_show_delay_ms = 500,
    },

    ghost_text = { enabled = false },
  },
  signature = {
    enabled = true,
    window = {
      show_documentation = false,
    },
  },
  sources = {
    -- `lazydev` only for Lua buffers, where ftplugin/lua_lazydev.lua has already
    -- installed and configured it.
    default = function()
      local sources = { "lsp", "path", "buffer" }
      if vim.bo.filetype == "lua" then
        table.insert(sources, 1, "lazydev")
      end
      return sources
    end,

    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        -- make lazydev completions top priority
        score_offset = 100,
      },

      path = {
        name = "Path",
        module = "blink.cmp.sources.path",
        score_offset = 3,
        opts = {
          -- Path completion from cwd instead of
          -- current buffer's directory
          get_cwd = function(_)
            return vim.fn.getcwd()
          end,
        },
      },
      -- snippets = {
      --   name = 'Snippets',
      --   module = 'blink.cmp.sources.snippets',
      --   score_offset = -3,
      --   opts = {
      --     -- NOTE: these should be similar to what is defined
      --     -- for `nvim-snippets` in `snippets.lua`.
      --     friendly_snippets = false,
      --     search_paths = { vim.fn.stdpath 'config' .. '/snippets' },
      --     -- global_snippets = { 'all' },
      --     ignored_filetypes = {},
      --     -- extended_filetypes = {
      --     --   markdown = { 'html' },
      --     -- },
      --   },
      -- },
    },
  },
  fuzzy = { implementation = "lua" },
})
