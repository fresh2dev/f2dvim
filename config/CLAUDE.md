# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the Neovim
config in this directory.

## What this is

A personal Neovim configuration (Neovim 0.12+, verified against v0.12.5). It began
as a `nvim-lua/kickstart.nvim` derivative — a few `kickstart-*` augroup names and
commented-out kickstart blocks survive — but has been restructured away from a
single-file config.

It is the `config/` directory of the f2dvim project; the project's `justfile` serves
it too, and there is no justfile here. In short:

- `just link` in the project root symlinks this directory to
  `~/.config/${NVIM_APPNAME:-nvim}`. On a linked machine, edits here are live on the next
  `nvim` start.
- `vim.pack` writes `nvim-pack-lock.json` through that symlink into this directory, so
  plugin installs and updates appear as diffs in the repo. Commit the
  lockfile with the change that caused it.
- Every external tool and language server this config needs is installed by mise from
  fresh2dev's dotfiles (`home/.config/mise/config.toml` there), not from this project.
  Add new ones there; there is no Mason.

## Commands

```sh
just -f ../justfile link    # symlink this directory to ~/.config/${NVIM_APPNAME:-nvim}
just -f ../justfile update  # vim.pack.update() headlessly, no review buffer
just -f ../justfile prune   # delete plugins no plugin/ or ftplugin/ file declares
stylua .                    # format
```

There is no test suite and no lint target. Verify changes by hand, from this
directory:

```sh
nvim --headless -c 'qa'                                                # startup errors surface here
nvim --headless -c 'e ../README.md' -c 'e init.lua' -c 'qa'            # install ftplugin plugins
nvim --headless -c 'lua vim.pack.update(nil, {offline=true})' -c 'qa'  # plugin state
stylua --check .                                                       # formatting
```

These run whatever `~/.config/nvim` points at, which is this directory on a linked
machine. Opening one markdown and one Lua buffer makes the `ftplugin/` plugins get
installed and land in `nvim-pack-lock.json` (the lockfile only gains an entry when a
plugin is first installed). `-c` commands run before `VimEnter`, so fugitive's `:Gcd`
has not moved the working directory yet and the relative paths resolve here.

Lua here is formatted with **stylua** per `.stylua.toml` (88 columns, 2-space indent,
double quotes, `collapse_simple_statement = "Never"`). stylua finds that file from the
formatted file's directory, so any treefmt that runs stylua on these files applies it too.

Run `stylua .` here before committing.

## Architecture

### Plugin management: `vim.pack`, one file per plugin

This config uses Neovim's **built-in `vim.pack`**, not lazy.nvim/packer/paq. There
is no central plugin spec table. The only module under `lua/` is `lua/util.lua`
(cross-file helpers: `cabbrev`, `keep_cursor`); plugin configuration never goes
there. Instead:

- Every plugin lives in its own `plugin/NN-<name>.lua`, which calls `vim.pack.add({ { src = "https://github.com/..." } })` and then immediately configures the plugin (`require(...).setup{}`, keymaps, autocmds, user commands).
- Neovim auto-sources `plugin/*.lua` **alphabetically, after `init.lua`**. The numeric prefix is the only load-order mechanism:
  - `00-` — must run first (`00-colorscheme.lua`)
  - `90-` — infrastructure other configs depend on (`90-lspconfig.lua`, `90-treesitter.lua`)
  - `99-` — everything else, order-independent
- **Everything is eager.** There is no lazy-loading layer. `vim.pack.add` installs missing plugins synchronously on first start, so the first `nvim` on a fresh machine is slow.
- **Each file declares every plugin it needs**, even if another file also lists it (`vim.pack.add` is idempotent). `nvim-web-devicons` appears in four files and `promise-async` in two; that is deliberate so each file is self-contained. There is no shared "deps" file.
- Deferring load to a filetype is done with **`ftplugin/`**, not with plugin specs: `ftplugin/lua_lazydev.lua` and `ftplugin/markdown.lua` call `vim.pack.add` at first use of that filetype. Because ftplugin files run for *every* buffer of that filetype, the install/`setup()` part is guarded by a `vim.g.loaded_<name>_config` flag; only buffer-local mappings sit outside the guard. Use the `<filetype>_<suffix>.lua` form to add a second file for a filetype without clobbering the first. `lazydev` is owned entirely by its ftplugin; blink adds the `lazydev` completion source only for Lua buffers.

Adding a plugin means adding one new `plugin/99-*.lua` file — do not thread it
into an existing file unless the two are genuinely coupled.

Build steps after install/update are centralised in `init.lua` SECTION 2, in a
single `PackChanged` autocmd that dispatches on `ev.data.spec.name` (currently
only `nvim-treesitter` → `:TSUpdate`). Add new build hooks there, not in the
plugin's own file.

### `init.lua`

Two labelled sections, ~730 lines and ~65 lines:

1. **SECTION 1: FOUNDATION** — leader keys, all `vim.o`/`vim.opt` options, core keymaps (including a `vim-unimpaired`-style bracket-pair family reimplemented in Lua), basic autocmds, netrw settings, ripgrep-backed `:Grep`/`:LGrep` user commands with cabbrev routing from `:grep`.
2. **SECTION 2: PLUGIN MANAGER HOOKS** — the `PackChanged` build dispatcher described above.

No plugin is loaded from `init.lua`.

### LSP (`plugin/90-lspconfig.lua`)

- Servers are declared in one `servers` table, then applied with a `vim.lsp.config(name, server)` + `vim.lsp.enable(name)` loop. Add a server by adding a table entry; use `root_markers`, not the deprecated `lspconfig.util.root_pattern`.
- **There is no Mason.** Language servers must be on `$PATH` already.
- **`stylua` is an LSP client here** (`stylua --lsp`, filetype `lua`) and it is the Lua *formatter*: conform skips Lua (see Formatting below) and the stylua server formats on save. `lua_ls` has `documentFormattingProvider` disabled in `on_init` **and** `Lua.format.enable = false` so the two never both format. Don't re-enable it. Workspace-library settings for Neovim config work come from lazydev, not from `lua_ls.on_init`.
- All LSP keymaps are set inside the `LspAttach` autocmd, buffer-local, prefixed `LSP:` in their `desc`. Neovim's own defaults (`K`, `grn`, `gra`, `grr`, `gri`, `gO`) are not re-declared; only the maps routed through fzf-lua (`gd`, `grr`, `gri`, `gI`, `gO`) and the `<leader>c*` aliases are. `symbol-usage` is set up once at file top level, not per attach.

### Formatting (`plugin/99-conform.lua`)

conform.nvim is configured with a single formatter for all filetypes:
`["_"] = { "treefmt" }`, rooted at `.git`/`treefmt.toml`/`.treefmt.toml` with
`require_cwd = false`. Per-language formatter entries are all commented out
deliberately — formatting is delegated to whatever `treefmt` the target project
configures.

The exception is the `lsp_formatted` table at the top of the file (currently
`{ lua = true, toml = true }`, formatted by `stylua --lsp` and `tombi lsp`
respectively): for those filetypes `format_on_save` returns
`lsp_format = "prefer"` with an empty formatter list, so the LSP server formats
and treefmt is skipped. To move another filetype to LSP formatting, add it there
and make sure its server is enabled in `90-lspconfig.lua`.

Format-on-save is gated on `vim.b.disable_autoformat`, toggled by the
`:ConformEnable` / `:ConformDisable` / `:ConformToggle` user commands.

### Treesitter (`plugin/90-treesitter.lua`)

Pinned to the `main` branch (the new API). A `parsers` list is installed up front,
and a `FileType` autocmd auto-installs and attaches any parser not in that list.
`gitcommit` is commented out of the eager list because its parser is very slow
to compile, but there is no exclusion mechanism: opening a commit buffer still
auto-installs it. Highlighting and indent are started manually via `vim.treesitter.start()` /
`indentexpr`; treesitter folding is present but commented out (folds come from
`nvim-ufo` instead).

### Keymap conventions

- Leader and localleader are both `<Space>`.
- Leader groups are registered in the `which-key` spec in `plugin/99-which-key.lua`: `<leader>c` Code, `<leader>f` Find, `<leader>g` Git (`<leader>gh` Git Hunk, gitsigns), `<leader>l` Lazygit, `<leader>p` replace-with-register operator (mini.operators), `<leader>q` Quit, `<leader>t` Toggle. **When adding a mapping under a new leader group, add the group to that spec.** `<localleader>m` (Markdown) is the exception: it is buffer-local, registered with `which-key.add({ buffer = ... })` in `ftplugin/markdown.lua`.
- Every mapping gets a `desc`; group letters are marked in the description with brackets (`"[G]oto [D]efinition"`).
- Ownership of contested keys, so they are not re-declared elsewhere:
  - `<leader>gd` is Diffview (`99-diffview.lua`); fugitive single-file diffs use `:Gvdiffsplit` or `dt` in the status buffer.
  - `gs` / `gS` are fzf-lua's document / workspace symbol pickers (`99-fzf.lua`, global, not under `<leader>f`). mini.operators' sort operator (default prefix `gs`) is disabled in `99-mini.operators.lua` for that reason; don't re-enable it.
  - gitsigns hunk actions live under `<leader>gh*` (buffer-local) so they never shadow the global fugitive `<leader>g*` maps.
  - `n`/`N` are defined in `99-hlslens.lua` (direction-aware, all of `n`/`x`/`o`), not `init.lua`.
  - `s`/`S`: normal `s`/`S` and visual `s` are vim-sneak (`99-sneak.lua`); visual `S` is mini.surround's "surround selection" (`99-mini.surround.lua`). Neither is mapped in operator-pending mode, so `ys`/`ds`/`cs` keep working. cutlass maps `s`/`S` first and is deliberately overridden by these later files. The visual `S` mapping must stay a `:<C-u>lua MiniSurround.add("visual")<CR>` command mapping, not a Lua callback: leaving Visual mode via `:` is what refreshes the `'<`/`'>` marks the function reads, and a callback sees the previous selection's marks (wrong text, or an out-of-range cursor error).
  - `<C-hjkl>` window navigation and `<C-Arrow>` resize come from mini.basics (`99-mini.basics.lua`); `zellij.vim` then overrides `<C-hjkl>` with its navigator (falls back to `wincmd`). `init.lua` only un-maps them in netrw.
  - The core buffer/window keymaps (`<leader>w`, `<leader>x`, `<leader>q*`) and the `:Quit*` / `:Bdelete` commands live in `99-mini.bufremove.lua`. Bulk deletes (`:QuitHidden`, `:QuitOther`, `:QuitAll`) only touch listed buffers with an empty `buftype`, skip modified buffers unless given `!`, and report what they kept.
  - The Diffview keymap table is intentionally exhaustive (`disable_defaults = true`); don't shrink it to overrides.
  - Markdown buffers (`ftplugin/markdown.lua`) map `<CR>`, `<Tab>`, `<S-Tab>`, `<BS>`, `<A-CR>`, `o`, `O`, `[[`/`]]` and `[f`/`]f` buffer-locally to markdown-plus `<Plug>` mappings. The plugin's own defaults are disabled (`keymaps.enabled = false`) because `<localleader>` is `<Space>` and its `<localleader>t`/`<localleader>lt`/`]b` defaults would shadow the Toggle and Lazygit groups and buffer navigation; the context-aware keys hand the key back to blink/autopairs/native outside lists and tables. `<BS>` is the one key not mapped straight to a `<Plug>`: nvim-autopairs re-maps `<BS>` buffer-locally from its own `FileType` autocmd (which runs after the ftplugin), so the markdown file applies an expression mapping via `vim.schedule` that removes an empty list marker and otherwise calls `autopairs_bs()`. `gd` and `<C-t>` are deliberately not mapped.
- Command-line abbreviations go through `require("util").cabbrev(lhs, rhs)` (only fires when `lhs` is the whole command line) — used for `grep`→`Grep`, `lgrep`→`LGrep`, `g`/`git`→`Git`.
- Mappings that must leave the cursor where it was wrap the edit in `require("util").keep_cursor(fn)` (`.` and `[<Space>`/`]<Space>` in `init.lua`). It tracks the cursor with an extmark, so the cursor stays on the same text when `fn` adds or removes lines, and it cannot end up past the end of the buffer. Sticky yank (`y`/`Y`) cannot use it: the operator runs after the expr mapping returns, and `g@` moves the cursor before calling `operatorfunc`. Instead it saves the window view (`winsaveview`) in the mapping and restores it from `TextYankPost`, only in the same window and buffer. A deferred `ModeChanged` (`*:n*`) clears the saved view, so a cancelled `y<Esc>` never makes a later `:yank` jump back to an old position. Mappings that must repeat as a whole (the `[p` family, `[e`/`]e`, `[<Space>`/`]<Space>`) are wrapped in `repeatable(lhs, fn)` in `init.lua` (vim-repeat); `.` calls `repeat#run` when `g:repeat_tick == b:changedtick`, else `keep_cursor` around `normal! .`.
- Fugitive runs `:Gcd` on `VimEnter`, so the cwd is the git root for the whole session; fzf-lua `oldfiles`, `:Grep`, blink's path source and Snacks scratch all inherit that.

### Deliberate deviations — do not "fix" these

- `vim.g.editorconfig = false` — Neovim's EditorConfig integration conflicts with `vim-symlink` (upstream issue linked in `init.lua`).
- `vim.o.modeline = false` — mitigates editor-config injection from untrusted files.
- `swapfile` and `writebackup` are off (files are assumed to be in version control); `undofile` is on, with `fundo` for persistence.
- Over SSH, `init.lua` sets `vim.g.clipboard` to an OSC 52 provider: copy via `vim.ui.clipboard.osc52` plus a JSON write of `{ lines, regtype }` to a shared per-user file under `stdpath("run")`; paste returns that file's entry (the latest yank of any instance on the host, which is what makes cross-pane `p` work) or, if unreadable, the instance's own last yank from a Lua table. The block is gated on `$SSH_TTY` with no `$DISPLAY`/`$WAYLAND_DISPLAY`/`$TMUX` and an unset `g:clipboard`, so local sessions keep Neovim's normal tool detection — keep it that way for portability. Neovim's own OSC 52 auto-detection cannot be relied on: multiplexers swallow its DA1/XTGETTCAP probe and it disables itself when `'clipboard'` is set. The clipboard is deliberately *not* read back through OSC 52 (terminals decline it by default and Neovim would stall on every `p`); Neovim empties the register *before* calling the provider's paste, so paste must always return `{ lines, regtype }` — never `0`, which wipes the register — and regtype must be trimmed to one character (blockwise carries a width).
- `laststatus = 3` (global statusline) is assumed by the snacks `zen` config.
- Snacks' `picker` and `quickfile` are disabled on purpose — fzf-lua is the picker and the `vim.ui.select` handler. `Snacks.picker.undo` / `Snacks.picker.projects` are still called directly because fzf-lua has no equivalent.

## f2dvim

f2dvim (the parent directory) packages this directory, minus the Plugin files on its
Exclusion list, for machines that cannot reach GitHub; it runs this config unchanged
with `vim.pack.add` replaced by `packadd`. Keep the config working when an external
tool or language server is missing (check with `vim.fn.executable`), keep plugins pure
Lua/Vimscript or put them on the Exclusion list, and run `just test` in `..` after
adding or removing a plugin.

## External tool dependencies

Beyond the language servers, the config shells out to: `rg` (`grepprg`, fzf-lua),
`fd`, `bat` (fzf-lua preview; optional, falls back to the builtin previewer), `treefmt` (formatting for everything except the
`lsp_formatted` filetypes), `stylua` (>= 2.x, run as an LSP for Lua), `tombi`
(TOML language server and formatter), `lazygit`, and `delta`
(fzf-lua git diffs, when installed). Missing binaries fail at use time, not at
startup. All of them, and the language servers, are pinned in fresh2dev's dotfiles'
global mise config; a new dependency gets a pinned entry there too.
