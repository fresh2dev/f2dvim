-- [[ LSP Configuration ]]

vim.pack.add({
  {
    src = "https://github.com/neovim/nvim-lspconfig",
  },
  {
    src = "https://github.com/j-hui/fidget.nvim",
  },
  {
    src = "https://github.com/Wansmer/symbol-usage.nvim",
  },
})

require("fidget").setup({})

-- Display reference / definition / implementation counts above symbols.
local SymbolKind = vim.lsp.protocol.SymbolKind
require("symbol-usage").setup({
  kinds = { SymbolKind.Class, SymbolKind.Method, SymbolKind.Function },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    -- Neovim's own `K`, `grn`, `gra`, `grx` and insert-mode `<C-s>` are not
    -- re-declared; nor is `[d`/`]d`, whose float comes from `jump.on_jump` in init.lua.
    local pick = function(keys, source, desc)
      map(keys, function()
        Snacks.picker[source]()
      end, desc)
    end

    pick("gd", "lsp_definitions", "[G]oto [D]efinition")

    -- Open signature help (normal mode; insert-mode <C-s> is a Neovim default)
    map("<C-s>", vim.lsp.buf.signature_help, "Signature Help")
    pick("grr", "lsp_references", "[G]oto [R]eferences")
    pick("gri", "lsp_implementations", "[G]oto [I]mplementation")
    pick("grt", "lsp_type_definitions", "[G]oto [T]ype Definition")
    pick("gO", "lsp_symbols", "[D]ocument [S]ymbols")
    pick("grI", "lsp_incoming_calls", "[G]oto [I]ncoming Calls")
    pick("grO", "lsp_outgoing_calls", "[G]oto [O]utgoing Calls")

    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

    -- NOTE: disabled in favor of `Snacks.toggle.diagnostics`
    -- -- Toggle diagnostics
    -- map('<leader>td', function()
    --   vim.diagnostic[vim.diagnostic.is_enabled() and 'disable' or 'enable']()
    -- end, '[T]oggle [D]iagnostics')

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- dprint is the only formatter: strip formatting from every other server
    -- (formatexpr and vim.lsp.buf.format check capabilities at call time), and
    -- format on save through dprint unless `:FormatDisable`d.
    if client and client.name ~= "dprint" then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    elseif client then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = event.buf,
        group = vim.api.nvim_create_augroup("dprint-format-on-save", { clear = false }),
        callback = function(ev)
          if not vim.b[ev.buf].disable_autoformat then
            vim.lsp.buf.format({ bufnr = ev.buf, name = "dprint", timeout_ms = 1000 })
          end
        end,
      })
    end

    if
      client and client:supports_method("textDocument/documentHighlight", event.buf)
    then
      local highlight_augroup =
        vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({
            group = "kickstart-lsp-highlight",
            buffer = event2.buf,
          })
        end,
      })
    end

    -- -- NOTE: disabled in favor of `Snacks.toggle.inlay_hints()`
    -- -- The following code creates a keymap to toggle inlay hints in your
    -- -- code, if the language server you are using supports them
    -- --
    -- -- This may be unwanted, since they displace some of your code
    -- if client and client:supports_method('textDocument/inlayHint', event.buf) then
    --   map(
    --     '<leader>th',
    --     function()
    --       vim.lsp.inlay_hint.enable(
    --         not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }
    --       )
    --     end,
    --     '[T]oggle Inlay [H]ints'
    --   )
    -- end
  end,
})

-- Language servers. There is no Mason: every server must already be on $PATH.
---@type table<string, vim.lsp.Config>
local servers = {
  ty = {
    filetypes = { "python" },
    settings = {
      ty = {
        configuration = {
          -- Off by default; flags names bound only on some paths (e.g. set
          -- inside an `if`, used after it). No false positives on a real codebase.
          rules = { ["possibly-unresolved-reference"] = "error" },
        },
      },
    },
  },
  ruff = {
    filetypes = { "python" },
    init_options = {
      settings = {
        -- Server settings should go here
        -- logLevel = 'debug',
        -- logFile = '/tmp/ruff.log',
        organizeImports = false,
      },
    },
  },
  just = {
    filetypes = { "just" },
    init_options = {},
  },
  gopls = {
    filetypes = { "go", "gomod" },
    -- cmd = {...},
    -- capabilities = {},
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
        gofumpt = true,
      },
    },
  },
  rust_analyzer = {
    filetypes = { "rust" },
  },
  tombi = {
    filetypes = { "toml" },
  },
  bashls = {
    filetypes = { "sh", "bash", "zsh" },
  },
  -- Workspace library / runtime settings for Neovim config work are injected
  -- lazily by lazydev (ftplugin/lua_lazydev.lua); don't duplicate them here.
  lua_ls = {},
  -- The only formatter (see the LspAttach autocmd above). A project's
  -- dprint.json wins; elsewhere the global ~/.config/dprint/dprint.jsonc
  -- applies. `filetypes` replaces lspconfig's list, so it repeats it.
  dprint = {
    filetypes = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "json",
      "jsonc",
      "markdown",
      "python",
      "toml",
      "rust",
      "roslyn",
      "graphql",
      "lua",
      "go",
      "sh",
      "bash",
      "zsh",
      "just",
    },
    init_options = { useGlobalConfig = true },
  },
}

for _, state in ipairs({ "Disable", "Enable" }) do
  vim.api.nvim_create_user_command("Format" .. state, function()
    vim.b.disable_autoformat = state == "Disable"
  end, { desc = state .. " format on save (buffer)" })
end
vim.api.nvim_create_user_command("FormatToggle", function()
  vim.b.disable_autoformat = not vim.b.disable_autoformat
end, { desc = "Toggle format on save (buffer)" })

-- Servers that register formatting dynamically (ruff) would slip past the
-- LspAttach strip above; refusing dynamic registration makes them declare it up front.
vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      formatting = { dynamicRegistration = false },
      rangeFormatting = { dynamicRegistration = false },
    },
  },
})

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
