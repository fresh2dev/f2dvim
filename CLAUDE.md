# CLAUDE.md

## What this repo is

**f2dvim**: Fresh2dev's Neovim config (`config/`) and its Plugins, packaged as one pure-Python wheel with a launcher. See `README.md` for users and `GLOSSARY.md` for the terms (Home machine, Plugin file, Exclusion list, Stale Plugin).

Generated from the [copier-python](https://github.com/fresh2dev/copier-python) template; the answers are in `.copier-answers.yml`.

## Architecture

- `config/`: the Neovim config itself; see [Neovim config](#neovim-config-config) below.
- `src/f2dvim/`: the package. `__main__.py` is the `f2dvim` command: it execs `nvim` with `NVIM_APPNAME=f2dvim`, the packaged `init.lua`, and `stub.lua`, which replaces `vim.pack.add` with `packadd`. `docs/adr/0001-f2dvim-launcher.md` explains why.
- `scripts/bundle.py`: stages the config (minus the Exclusion list in `[tool.f2dvim]`) and each declared Plugin, `git archive`d at its `nvim-pack-lock.json` revision from the Home machine's `vim.pack` install. Also a small CLI (`stale`, `exclude`, `plugins`).
- `scripts/hatch_build.py`: the hatchling hook (`path` in `[tool.hatch.build.targets.wheel.hooks.custom]`) that puts `bundle.py`'s output into the wheel. Without that table the wheel ships no config.
- `tests/`: unit tests for `bundle.py`, plus a smoke test that builds the wheel and runs it headlessly with `uvx`. The smoke test skips without `nvim` or installed Plugins, so it only runs on the Home machine, not in CI.

## Commands

Tasks run through `just` (bare `just` lists them). Most tools are pinned in the justfiles and run via `uvx` / `uv run --with`; the CLIs they need on `PATH` (just, uv, prek, wrangler) are pinned in `mise.toml`, so install them with `mise install` (after `mise trust`). treefmt and its formatters come from the machine. CI installs the same `mise.toml` tools and runs the same recipes.

- `just format [paths]`: format with treefmt (`.treefmt.toml`).
- `just changelog`: prepend unreleased commits to `CHANGELOG.md` with git-cliff.
- `just install`: sync `.venv` with `uv`.
- `just test`, `just lint` (alias `check`), `just fix`, `just check-types`, `just check-docstrings`.
- `just build`, `just publish-test`, `just publish`. Building needs the Plugins installed by `vim.pack` on this machine.
- `just link`, `just update`, `just prune`: symlink `config/` to `~/.config/${NVIM_APPNAME:-nvim}`, update Plugins and the lockfile headlessly (no review buffer), delete Stale Plugins (declared by no `plugin/` or `ftplugin/` file).
- `stylua config src`: format the Lua; run it before committing Lua changes.
- `just docs-serve`, `just docs-build`, `just docs-publish`.
- `prek run --all-files`: run the git hooks (this project uses `prek`, not `pre-commit`).

## Conventions

- Commit messages follow Conventional Commits; `just changelog` groups them by type and skips `docs`/`style`/`build`/`ci`/`test`.
- The commit hook runs `just format` and `just check ./src`; don't rename the recipes it calls.
- The version comes from unprefixed git tags (`0.1.0`) via `uv-dynamic-versioning`. `src/f2dvim/__version__.py` is generated and gitignored, so don't edit it.
- Dev dependencies go in `pyproject.toml` dependency groups (`pytest` is in `tests`), not only in a justfile `--with`.
- `docs/index.md`, `docs/changelog.md` and `docs/license.md` include `README.md`, `CHANGELOG.md` and `LICENSE`, so edit those root files instead.
- zensical builds the docs into `public/r/f2dvim` (`site_dir` in `mkdocs.yml`), which `wrangler.toml` serves at <https://f2dv.com/r/f2dvim>.
- Template-owned files (`justfile`, `*.just`, `.treefmt.toml`, `.cliff.toml`, `.pre-commit-config.yaml`, `mkdocs.yml`, `wrangler.toml`) are reset by `copier recopy --trust -r dev --skip 'src/**/*' --skip-answered`; review `git diff` afterwards. Keep the justfile's Project-specific recipes (`link`, `update`, `prune`) and the `hooks.custom` table in `pyproject.toml`.
- CI: `.github/workflows/checks.yml` runs every hook except `format` (CI doesn't format), `check-types`, `check-docstrings`, and `just test` on the minimum and latest Python. Pushing a version tag runs `release.yml`, which publishes the docs after those checks pass. It does not publish to PyPI: the runner has no Plugins to build with, so the wheel is built and published from the Home machine (README, "Releasing"). `just publish` would upload the sdist too; use `uv publish dist/*.whl`.
- `.beads/` is gitignored on purpose.

## Neovim config (`config/`)

A personal Neovim configuration (Neovim 0.12+, verified against v0.12.5). It began
as a `nvim-lua/kickstart.nvim` derivative — a few `kickstart-*` augroup names and
commented-out kickstart blocks survive — but has been restructured away from a
single-file config. Paths in this section are relative to `config/`.

- `just link` symlinks `config/` to `~/.config/${NVIM_APPNAME:-nvim}`. On a linked
  machine, edits to `config/` are live on the next `nvim` start.
- `vim.pack` writes `nvim-pack-lock.json` through that symlink into `config/`, so
  plugin installs and updates appear as diffs in the repo. Commit the
  lockfile with the change that caused it.
- Every external tool and language server the config needs is installed by mise from
  fresh2dev's dotfiles (`home/.config/mise/config.toml` there), not from this project.
  Add new ones there; there is no Mason.

### Verifying config changes

There is no test suite for the config itself. Verify changes by hand, from `config/`:

```sh
cd config
nvim --headless -c 'qa'                                                # startup errors surface here
nvim --headless -c 'e ../README.md' -c 'e init.lua' -c 'qa'            # install ftplugin plugins
nvim --headless -c 'lua vim.pack.update(nil, {offline=true})' -c 'qa'  # plugin state
```

These run whatever `~/.config/nvim` points at, which is `config/` on a linked
machine. Opening one markdown and one Lua buffer makes the `ftplugin/` plugins get
installed and land in `nvim-pack-lock.json` (the lockfile only gains an entry when a
plugin is first installed). `-c` commands run before `VimEnter`, so fugitive's `:Gcd`
has not moved the working directory yet and the relative paths resolve to `config/`.

Lua is formatted with **stylua** per the root `.stylua.toml` (88 columns, 2-space
indent, double quotes, `collapse_simple_statement = "Never"`). The stylua CLI only
reads the working directory's config, so run `stylua config src` (or `just format`)
from the root; inside `config/` it needs `--search-parent-directories`. The stylua
language server finds the file from its root marker, searching up from the edited file.

### Plugin management: `vim.pack`, one file per plugin

This config uses Neovim's **built-in `vim.pack`**, not lazy.nvim/packer/paq. There
is no central plugin spec table. The only module under `lua/` is `lua/util.lua`
(cross-file helpers: `cabbrev`, `keep_cursor`, `sessions`); plugin
configuration never goes there. Instead:

- Every plugin lives in its own `plugin/NN-<name>.lua`, which calls `vim.pack.add({ { src = "https://github.com/..." } })` and then immediately configures the plugin (`require(...).setup{}`, keymaps, autocmds, user commands).
- Neovim auto-sources `plugin/*.lua` **alphabetically, after `init.lua`**. The numeric prefix is the only load-order mechanism:
  - `00-` — must run first (`00-colorscheme.lua`)
  - `90-` — infrastructure other configs depend on (`90-lspconfig.lua`, `90-treesitter.lua`, `90-mini.icons.lua`)
  - `99-` — everything else, order-independent
- **Everything is eager.** There is no lazy-loading layer. `vim.pack.add` installs missing plugins synchronously on first start, so the first `nvim` on a fresh machine is slow.
- **Each file declares every plugin it needs**, even if another file also lists it (`vim.pack.add` is idempotent). `mini.icons` appears in four files (set up and devicons-mocked in `90-mini.icons.lua`), `snacks.nvim` in six, `promise-async` in two; that is deliberate so each file is self-contained. There is no shared "deps" file.
- Deferring load to a filetype is done with **`ftplugin/`**, not with plugin specs: `ftplugin/lua_lazydev.lua` and `ftplugin/markdown.lua` call `vim.pack.add` at first use of that filetype. Because ftplugin files run for *every* buffer of that filetype, the install/`setup()` part is guarded by a `vim.g.loaded_<name>_config` flag; only buffer-local mappings sit outside the guard. Use the `<filetype>_<suffix>.lua` form to add a second file for a filetype without clobbering the first. `lazydev` is owned entirely by its ftplugin; blink adds the `lazydev` completion source only for Lua buffers.

snacks.nvim is split like mini, one file per module, but has a single setup:
`99-snacks.lua` makes the only `Snacks.setup` call (small modules, toggles), and
each `99-snacks.<module>.lua` assigns `Snacks.config.<module>` (with
`enabled = true`) instead. Snacks reads a module's config on `UIEnter` or first
use, so file order doesn't matter; a module that `Snacks.setup` itself reads
(`notifier`, `statuscolumn`) must stay in the setup call. The fzj `sessions`
helper they share is in `lua/util.lua`.

Adding a plugin means adding one new `plugin/99-*.lua` file — do not thread it
into an existing file unless the two are genuinely coupled.

Build steps after install/update are centralised in `init.lua` SECTION 2, in a
single `PackChanged` autocmd that dispatches on `ev.data.spec.name` (currently
only `nvim-treesitter` → `:TSUpdate`). Add new build hooks there, not in the
plugin's own file.

### `init.lua`

Two labelled sections, ~730 lines and ~65 lines:

1. **SECTION 1: FOUNDATION** — leader keys, all `vim.o`/`vim.opt` options, core keymaps (including a `vim-unimpaired`-style `[p` linewise-paste family; the list pairs `[a`/`[b`/`[q`/`[l`, `[d` and `[<Space>` are Neovim defaults and are not re-declared), basic autocmds, netrw settings, ripgrep-backed `:Grep`/`:LGrep` user commands with cabbrev routing from `:grep`.
2. **SECTION 2: PLUGIN MANAGER HOOKS** — the `PackChanged` build dispatcher described above.

No plugin is loaded from `init.lua`.

### LSP (`plugin/90-lspconfig.lua`)

- Servers are declared in one `servers` table, then applied with a `vim.lsp.config(name, server)` + `vim.lsp.enable(name)` loop. Add a server by adding a table entry; use `root_markers`, not the deprecated `lspconfig.util.root_pattern`.
- **There is no Mason.** Language servers must be on `$PATH` already.
- Python uses `ty` (type checking) and `ruff`; ruff's formatting is stripped like every other server's (see Formatting below).
- Workspace-library settings for Neovim config work come from lazydev, not from `lua_ls.on_init`.
- All LSP keymaps are set inside the `LspAttach` autocmd, buffer-local, prefixed `LSP:` in their `desc`. Neovim's own defaults (`K`, `grn`, `gra`, `grr`, `gri`, `grt`, `gO`) are not re-declared; only the maps routed through the Snacks picker (`gd`, `grr`, `gri`, `grt`, `gO`, plus `grI`/`grO` for incoming/outgoing calls) are. They call `Snacks.picker.*` from callbacks, so the file does not declare snacks. `symbol-usage` is set up once at file top level, not per attach.

### Formatting (`dprint lsp`, in `plugin/90-lspconfig.lua`)

There is no conform. `dprint lsp` is the only formatter: the `LspAttach`
autocmd sets `documentFormattingProvider` / `documentRangeFormattingProvider`
to `false` on every other client, and `vim.lsp.config("*")` declines dynamic
formatting registration so servers that register it late (ruff) can't slip
past. Don't re-enable formatting on another server.

dprint resolves the project's `dprint.json` per file; `useGlobalConfig = true`
falls back to fresh2dev's global `~/.config/dprint/dprint.jsonc` (exec plugin
running stylua, ruff, rumdl, tombi, shfmt, gofmt, rustfmt, just). The `dprint`
entry's `filetypes` replaces lspconfig's list, so it repeats that list; add a
filetype there to format it.

When dprint attaches, a buffer-local `BufWritePre` formats with
`vim.lsp.buf.format({ name = "dprint" })`, gated on `vim.b.disable_autoformat`
(`:FormatEnable` / `:FormatDisable` / `:FormatToggle`).

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
- Leader groups are registered in the `which-key` spec in `plugin/99-which-key.lua`: `<leader>f` Find, `<leader>g` Git (`<leader>gg` is Snacks lazygit; `<leader>gh` GitHub is Snacks gh), `<leader>p` replace-with-register operator (mini.operators), `<leader>q` Quit, `<leader>t` Toggle. **When adding a mapping under a new leader group, add the group to that spec.** `<localleader>m` (Markdown) is the exception: it is buffer-local, registered with `which-key.add({ buffer = ... })` in `ftplugin/markdown.lua`. A buffer-local map that fully matches fires without waiting, so a plugin's buffer-local `<localleader>` keys must not equal a global `<leader>` map or prefix; grug-far's are remapped in `99-grug-far.lua` for that reason.
- Never use `Alt`/`Meta` (`<A-…>`, `<M-…>`, `<a-…>`) as a modifier in any mapping this config defines, including plugin-internal keymap tables.
- Every mapping gets a `desc`; group letters are marked in the description with brackets (`"[G]oto [D]efinition"`).
- Ownership of contested keys, so they are not re-declared elsewhere:
  - `<leader>gd` is Diffview (`99-diffview.lua`); fugitive single-file diffs use `:Gvdiffsplit` or `dt` in the status buffer.
  - `gS` is mini.splitjoin's split/join toggle (`99-mini.splitjoin.lua`).
  - `gs` is mini.operators' sort operator (`99-mini.operators.lua`); the Snacks document / workspace symbol pickers are `<leader>fs` / `<leader>fS` (`99-snacks.picker.lua`).
  - `n`/`N` are defined in `99-hlslens.lua` (direction-aware, all of `n`/`x`/`o`), not `init.lua`.
  - `s`/`S`: normal `s`/`S` and visual `s` are vim-sneak (`99-sneak.lua`); visual `S` is mini.surround's "surround selection" (`99-mini.surround.lua`). Neither is mapped in operator-pending mode, so `ys`/`ds`/`cs` keep working. cutlass maps `s`/`S` first and is deliberately overridden by these later files. The visual `S` mapping must stay a `:<C-u>lua MiniSurround.add("visual")<CR>` command mapping, not a Lua callback: leaving Visual mode via `:` is what refreshes the `'<`/`'>` marks the function reads, and a callback sees the previous selection's marks (wrong text, or an out-of-range cursor error).
  - `<C-hjkl>` window navigation and `<C-Arrow>` resize come from mini.basics (`99-mini.basics.lua`); `zellij.vim` then overrides `<C-hjkl>` with its navigator (falls back to `wincmd`). `init.lua` only un-maps them in netrw.
  - The core buffer/window keymaps (`<leader>w`, `<leader>x`, `<leader>q*`) and the `:Quit*` / `:Bdelete` commands live in `99-mini.bufremove.lua`. Bulk deletes (`:QuitHidden`, `:QuitOther`, `:QuitAll`) only touch listed buffers with an empty `buftype`, skip modified buffers unless given `!`, and report what they kept.
  - The Diffview keymap table is intentionally exhaustive (`disable_defaults = true`); don't shrink it to overrides.
  - Markdown buffers (`ftplugin/markdown.lua`) map `<CR>`, `<Tab>`, `<S-Tab>`, `<BS>`, `<A-CR>`, `o`, `O`, `[[`/`]]` and `[f`/`]f` buffer-locally to markdown-plus `<Plug>` mappings. The plugin's own defaults are disabled (`keymaps.enabled = false`) because `<localleader>` is `<Space>` and its `<localleader>t`/`]b` defaults would shadow the Toggle group and buffer navigation; the context-aware keys hand the key back to blink/mini.pairs/native outside lists and tables. `<BS>` is the one key not mapped straight to a `<Plug>`: it is an expression mapping that removes an empty list marker and otherwise returns `MiniPairs.bs()`, so pairs still delete as a whole. `gd` and `<C-t>` are deliberately not mapped.
- Command-line abbreviations go through `require("util").cabbrev(lhs, rhs)` (only fires when `lhs` is the whole command line) — used for `grep`→`Grep`, `lgrep`→`LGrep`, `g`/`git`→`Git`.
- Mappings that must leave the cursor where it was wrap the edit in `require("util").keep_cursor(fn)` (`.` in `init.lua`). It tracks the cursor with an extmark, so the cursor stays on the same text when `fn` adds or removes lines, and it cannot end up past the end of the buffer. Sticky yank (`y`/`Y`) cannot use it: the operator runs after the expr mapping returns, and `g@` moves the cursor before calling `operatorfunc`. Instead it saves the window view (`winsaveview`) in the mapping and restores it from `TextYankPost`, only in the same window and buffer. A deferred `ModeChanged` (`*:n*`) clears the saved view, so a cancelled `y<Esc>` never makes a later `:yank` jump back to an old position. Mappings that must repeat as a whole (the `[p` family, `[e`/`]e`) are wrapped in `repeatable(lhs, fn)` in `init.lua` (vim-repeat); `.` calls `repeat#run` when `g:repeat_tick == b:changedtick`, else `keep_cursor` around `normal! .`.
- Fugitive runs `:Gcd` on `VimEnter`, so the cwd is the git root for the whole session; the Snacks pickers (`smart` filters to it), `:Grep` and blink's path source all inherit that.

### Deliberate deviations — do not "fix" these

- `vim.o.modeline = false` — mitigates editor-config injection from untrusted files.
- `swapfile` and `writebackup` are off (files are assumed to be in version control); `undofile` is on, with `fundo` for persistence.
- Over SSH, `init.lua` sets `vim.g.clipboard` to an OSC 52 provider: copy via `vim.ui.clipboard.osc52` plus a JSON write of `{ lines, regtype }` to a shared per-user file under `stdpath("run")`; paste returns that file's entry (the latest yank of any instance on the host, which is what makes cross-pane `p` work) or, if unreadable, the instance's own last yank from a Lua table. The block is gated on `$SSH_TTY` with no `$DISPLAY`/`$WAYLAND_DISPLAY`/`$TMUX` and an unset `g:clipboard`, so local sessions keep Neovim's normal tool detection — keep it that way for portability. Neovim's own OSC 52 auto-detection cannot be relied on: multiplexers swallow its DA1/XTGETTCAP probe and it disables itself when `'clipboard'` is set. The clipboard is deliberately *not* read back through OSC 52 (terminals decline it by default and Neovim would stall on every `p`); Neovim empties the register *before* calling the provider's paste, so paste must always return `{ lines, regtype }` — never `0`, which wipes the register — and regtype must be trimmed to one character (blockwise carries a width).
- `laststatus = 3` (global statusline) is assumed by the snacks `zen` config.
- Snacks' `quickfile` is disabled on purpose. `Snacks.picker` is the only picker and the `vim.ui.select` handler (ADR 0002); its defaults live in `Snacks.config.picker` in `99-snacks.picker.lua` (`files`/`grep`/`grep_word`: `rg`, hidden, follow; `layout = "vertical"`), so keymaps pass only what differs (`ignored = true` for `<leader>fF`/`<leader>fG`). Inside a picker, `<c-o>` is split below (`<c-s>` is unbound), `<c-/>` toggles the preview and every `<a-*>` default is set to `false`; Snacks sets up the picker on `UIEnter`, which headless `nvim` never fires.

### Packaging constraints

f2dvim packages `config/`, minus the Plugin files on its
Exclusion list, for machines that cannot reach GitHub; it runs this config unchanged
with `vim.pack.add` replaced by `packadd`. Keep the config working when an external
tool or language server is missing (check with `vim.fn.executable`), keep plugins pure
Lua/Vimscript or put them on the Exclusion list, and run `just test` after
adding or removing a plugin.

### External tool dependencies

Beyond the language servers, the config shells out to: `rg` (`grepprg`, the Snacks
file and grep pickers), `dprint` (`dprint lsp`, the only formatter; its global
config runs stylua, ruff, rumdl, tombi, shfmt, gofmt, rustfmt and just), `tombi`
(TOML language server), `lazygit`, and `gh` (Snacks gh). Missing binaries fail at
use time, not at startup. All of them, and the language servers, are pinned in fresh2dev's dotfiles'
global mise config; a new dependency gets a pinned entry there too.
