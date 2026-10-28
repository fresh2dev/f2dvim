<div align="center">
  <h1>f2dvim</h1>
  <hr>
  <img src="https://img.fresh2.dev/file/imgcap/1791145565-3DaE3tKEuq.svg" alt="logo" width="160">
  <p><em>Fresh2dev's Neovim config</em></p>
  <hr>
  <a href="https://f2dv.com/r/f2dvim/">Documentation</a> |
  <a href="https://github.com/fresh2dev/f2dvim/">Git Repo</a>
  <hr>
</div>

*f2dvim* is a complete Neovim setup: fresh2dev's config plus the ~50 plugins it uses,
pinned and packed into one pure-Python wheel. If you have `uv`, you can run it without
installing anything:

```sh
uvx f2dvim
```

> **Experimental.** f2dvim is my own personal config, published as is.
> Keymaps and plugins change between releases without notice.

<!-- TOC -->

## Table of Contents

- [Why](#why)
- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
- [How it works](#how-it-works)
- [Optional tools](#optional-tools)
- [What's left out](#whats-left-out)
- [The config](#the-config)
- [Things to know before you start](#things-to-know-before-you-start)
- [Keymap overview](#keymap-overview)
- [Core mappings (no plugin)](#core-mappings-no-plugin)
- [Plugins](#plugins)
  - [Appearance and UI](#appearance-and-ui)
  - [Editing](#editing)
  - [Motions and text objects](#motions-and-text-objects)
  - [Search and navigation](#search-and-navigation)
  - [Files, buffers, windows](#files-buffers-windows)
  - [Git](#git)
  - [LSP, completion, formatting, syntax](#lsp-completion-formatting-syntax)
  - [Integrations](#integrations)
  - [Filetype-specific](#filetype-specific)
  - [Libraries](#libraries)
- [User commands](#user-commands)
- [Extending the config](#extending-the-config)
- [Working on the config](#working-on-the-config)
- [Building from source](#building-from-source)
  - [Releasing](#releasing)
- [License](#license)

<!-- /TOC -->

## Why

- **Portable.** One `py3-none-any` wheel with no native code and no Python
  dependencies. It runs anywhere Python 3.12 and Neovim 0.12 do (tested on macOS).
- **Immutable.** The config and plugins ship inside the package and f2dvim never changes
  them: nothing is cloned, built or downloaded at startup, and `vim.pack.update()` does
  nothing. A given version is always the same editor. Edits made inside the installed
  package are lost on the next upgrade or reinstall; customize a fork instead.
- **Isolated.** f2dvim keeps its own shada, undo history and caches, and never touches
  `~/.config/nvim`, so it sits alongside your own Neovim setup.
- **Bootstrapped by `uv`.** `uvx f2dvim` tries it in one command; `uv tool install
  f2dvim` keeps it, and `uv tool upgrade f2dvim` updates it.

## Requirements

- Neovim 0.12 or newer, on `PATH`
- Python 3.12 or newer (`uv` can provide it)
- `git`, for the git plugins (fugitive, gitsigns, diffview)
- A [Nerd Font](https://www.nerdfonts.com) in your terminal, for icons in the statusline,
  pickers and file explorer

## Install

Run it once, without installing:

```sh
uvx f2dvim notes.md
```

Install it as a command:

```sh
uv tool install f2dvim     # or: pipx install f2dvim
f2dvim
```

Upgrade with `uv tool upgrade f2dvim`, or uninstall with `uv tool uninstall f2dvim`.

## Usage

`f2dvim` takes the same arguments as `nvim`:

```sh
f2dvim file.py
f2dvim -d old.txt new.txt
f2dvim +Git
```

To make it your default editor, so that `vi`, git and lazygit open f2dvim:

```sh
alias vi=f2dvim
export EDITOR=f2dvim
```

The keymaps and plugins are documented [below](#things-to-know-before-you-start).

## How it works

The `f2dvim` command runs your `nvim` with:

- `NVIM_APPNAME=f2dvim`, so state lives in `~/.local/share/f2dvim`,
  `~/.local/state/f2dvim` and `~/.cache/f2dvim`, and respects `$XDG_*` overrides
- the packaged `init.lua`, with the packaged config first on `runtimepath` and the
  packaged plugins on `packpath`
- a small shim that replaces `vim.pack.add()` with `packadd`, so the config's plugin
  declarations load the packaged copies

[ADR 0001](docs/adr/0001-f2dvim-launcher.md) explains why the config runs from inside
the package instead of being copied into `~/.config`.

Note: a bare `nvim` started from inside f2dvim (from `:terminal`, say) inherits
`NVIM_APPNAME=f2dvim`. It opens a stock config that shares f2dvim's state directories.

## Optional tools

f2dvim works without any of these. A missing tool only disables the feature that uses
it, and language servers that aren't installed are skipped.

| Tool | Used for | Install |
|---|---|---|
| `rg` | `:Grep`, file and grep pickers | your package manager |
| `lazygit` | `<leader>gg` | `go install github.com/jesseduffield/lazygit@latest` |
| `gh` (authenticated) | `<leader>gh*` GitHub pickers | your package manager |
| `dprint` | format on save (`dprint lsp`) | `npm i -g dprint` |
| `ruff`, `ty` | Python | `uv tool install ruff`, `uv tool install ty` |
| `tombi` | TOML | `uv tool install tombi` |
| `just-lsp` | justfiles | `uv tool install just-lsp` |
| `gopls` | Go | `go install golang.org/x/tools/gopls@latest` |
| `bash-language-server` | shell | `npm i -g bash-language-server` |
| `lua-language-server`, `rust-analyzer` | Lua, Rust | your package manager |

## What's left out

To keep the wheel pure Python, f2dvim leaves out:

- **nvim-treesitter**, because its parsers are native code. Neovim's built-in parsers
  (c, lua, markdown, query, vim, vimdoc) still work, and language servers provide
  semantic highlighting.
- **The zellij integrations**.

blink.cmp uses its pure-Lua fuzzy matcher instead of its Rust one.

## The config

f2dvim runs a personal Neovim configuration for **Neovim 0.12+**. It uses the editor's
built-in `vim.pack` plugin manager, keeps one config file per plugin, loads everything
eagerly, and leans on Neovim's own defaults wherever they are good enough.
Formatting is delegated to `dprint lsp`, using the project's `dprint.json` or,
outside one, the global `~/.config/dprint/dprint.jsonc`. Snacks is the picker, and tpope-style mnemonics are kept where
they exist (`ys`/`ds`/`cs`, `[q`/`]q`, `[p`/`]p`).

It lives in [`config/`](config); paths below are relative to it.

```text
init.lua            options, core keymaps, autocmds, :Grep, vim.pack build hooks
lua/util.lua        cross-file helpers (`cabbrev`, `keep_cursor`)
plugin/00-*.lua     must run first (colorscheme)
plugin/90-*.lua     infrastructure others depend on (LSP, treesitter)
plugin/99-*.lua     one plugin (or a port of one) per file, order-independent
ftplugin/           filetype-scoped plugins (markdown, Lua)
nvim-pack-lock.json pinned plugin revisions
```

Every `plugin/NN-name.lua` calls `vim.pack.add` for the plugin it configures and
then configures it in place: `setup()`, keymaps, autocmds, user commands. There
is no central plugin list. See `CLAUDE.md` for the conventions in detail.

## Things to know before you start

These are the choices most likely to surprise someone coming from stock Vim or
another distribution.

- **`<Space>` is the leader** (and local leader). Press it and wait about 1.5
  seconds to get a which-key popup of everything under it. `<leader>tk` shows
  buffer-local keymaps, `<leader>tK` all of them, `<leader>fk` searches them.
- **The clipboard is the system clipboard.** `'clipboard'` is `unnamedplus`, so
  every yank and put goes through the OS clipboard. Over SSH (where no
  `xclip`/`wl-copy` can work) yanks are sent to your terminal emulator with
  OSC 52 instead, so they land on the *local* machine's clipboard and can be
  pasted anywhere with the terminal's paste (Cmd+V / Ctrl+Shift+V), including
  other SSH sessions, zellij panes and Neovim instances. Every yank is also
  recorded in a per-user file on the server (`stdpath("run")`, e.g.
  `/run/user/<uid>/clipboard.json`), so `p` pastes the latest yank of any
  Neovim instance on that host, across zellij panes included. Text copied on
  your own machine comes in with Cmd+V. Local sessions are unaffected. See the
  comment in `init.lua`.
- **Small deletes and changes do not clobber your yank** (`99-cutlass.lua`). `x`, `X`,
  `c` and `C` (and visual `x` / `c`) go to the blackhole register, so the unnamed
  register and the clipboard keep your last yank. `d` still cuts, except when it
  removes only blank text (empty lines, spaces): that goes to the blackhole too.
- **`s` and `S` are vim-sneak**, not "substitute character". Type `s` plus two
  characters to jump forward, `S` to jump backward, `;`/`,` to repeat. `f`/`t`
  are sneak-enhanced too. Visual `s` extends the selection with a sneak jump;
  visual `S` is mini.surround. Use `cl` for the old `s`.
- **`<leader>p` is "replace with register"** (mini.operators): `<leader>piw`
  replaces the word under the cursor with what you last yanked, without
  touching the register. `<leader>pp` does the current line.
- **`cx` is exchange**: `cxiw` on one word, `cxiw` on another, and they swap.
  `cxx` exchanges lines; in visual mode the key is `X`. `gm` multiplies
  (duplicates).
- **`gs` sorts** (mini.operators): `gsip` sorts the paragraph's lines, and
  `gsi(` sorts the comma-separated items inside the parentheses.
- **Yanking keeps the cursor and the scroll position where they were**
  (sticky yank, so `ygg` no longer jumps to the top). `.` repeats without
  moving the cursor: it stays on the same text even when the change adds or
  removes lines above it. The exception is repeating the `[p` family, which
  replays the paste as a whole, just like the original.
- **`j`/`k` move by screen line** when there is no count, and by real line
  when there is one (`5j` still goes five lines down). `gj`/`gk` are freed up
  and jump to the next "edge" (indent change).
- **`n` always searches forward, `N` always backward**, no matter whether you
  searched with `/` or `?`. `<Esc>` in normal mode clears the search highlight.
- **`U` opens an undo tree** (Snacks) instead of the rarely useful "undo line".
- **`\` opens the file explorer** (mini.files) at the working directory and
  `|` opens it at the current file.
- **The working directory jumps to the git root on startup** (fugitive
  `:Gcd`). Fuzzy finding, `:Grep`, path completion and recent files are all
  relative to that.
- **Format on save is on** wherever `dprint lsp` attaches; dprint is the only
  formatter. `:FormatToggle` turns it off for the current buffer.
- **Diagnostics jump with `[d`/`]d`** and open a float when they land. `<C-s>`
  in normal mode shows signature help.
- **`<leader>x` is "I'm done with this"**: it closes the window if the buffer
  is visible elsewhere (or if every other buffer is already on screen in this
  tab), otherwise it deletes the buffer without disturbing the split layout.
- **No swap files, no backups; undo history is persistent** (`undofile` plus
  fundo). `'modeline'` is off, and Neovim's EditorConfig support is off because
  it conflicts with symlinked files.
- **Relative line numbers appear only in visual mode** (mini.basics).
- **`:grep`, `:lgrep`, `:g`, `:git` are abbreviations** for `:Grep`, `:LGrep`,
  `:Git`. They expand only when they are the whole command line.
- **In the terminal**, `<Esc><Esc>` or `<C-u>` leaves insert mode and `<C-w>`
  followed by a window key moves between windows without leaving first.
- Indentation defaults to **4 spaces** and is auto-detected per file
  (guess-indent). Line wrapping is off; `<leader>tw` toggles it.

## Keymap overview

Leader groups (which-key shows these):

| Prefix | Group | Where |
|---|---|---|
| `<leader>c` | Conflict (choose a side) | conflict-marker |
| `<leader>f` | Find (pickers, find and replace) | snacks, lspconfig, grug-far |
| `<leader>g` | Git (`<leader>gh` GitHub) | fugitive, flog, diffview, snacks (lazygit, gh) |
| `<leader>p` | Paste with replacement (operator) | mini.operators |
| `<leader>q` | Quit (windows, buffers, tabs) | mini.bufremove |
| `<leader>t` | Toggle | snacks, colorizer, which-key |
| `<localleader>m` | Markdown (markdown buffers only) | markdown-plus |

Bracket pairs (unimpaired-style, `[` previous / `]` next):

| Keys | Moves between |
|---|---|
| `[a` `]a` `[A` `]A` | argument list |
| `[b` `]b` `[B` `]B` | buffers |
| `[q` `]q` `[Q` `]Q` | quickfix entries |
| `[l` `]l` `[L` `]L` | location list entries |
| `[c` `]c` | git hunks (or diff hunks in diff mode) |
| `[x` `]x` | merge conflict markers |
| `[d` `]d` | diagnostics |
| `[e` `]e` | move current line / selection up / down |
| `[<Space>` `]<Space>` | add blank line above / below |
| `[p` `]p` `[P` `]P` | paste linewise above / below |
| `>p` `<p` `=p` (and `>P` `<P` `=P`) | paste linewise and shift / reindent |
| `[;` `];` | start of current context / next context (dropbar) |
| `[T` | jump up to the treesitter context line |
| `[z` `]z` `zj` `zk` | fold boundaries (builtin) |
| `[[` `]]` | markdown headings (markdown-plus) |
| `[f` `]f` | markdown code fences (markdown-plus) |

Operators and their prefixes:

| Keys | Operator | Plugin |
|---|---|---|
| `ys` `ds` `cs` `yss` | surround add / delete / change / line | mini.surround |
| `S` (visual) | surround selection | mini.surround |
| `cx` `cxx` (`X` in visual) | exchange | mini.operators |
| `gm` `gmm` | multiply (duplicate) | mini.operators |
| `<leader>p` `<leader>pp` `<leader>P` | replace with register (motion / line / to end of line) | mini.operators |
| `gs` `gss` | sort | mini.operators |
| `gc` `gcc` | toggle comment | Neovim |
| `ga` | align | vim-easy-align |
| `gz` `gZ` | zoom / zen mode | snacks |

## Core mappings (no plugin)

These live in `init.lua`, except the ones modelled on a plugin, which live in a
file named after it: `[p` and `[e` (`99-unimpaired.lua`), `.` (`99-repeat.lua`),
`y` / `Y` (`99-sticky-yank.lua`) and `gco` / `gcO` (`99-comment.lua`).

| Key | Mode | Action |
|---|---|---|
| `j` `k` `<Down>` `<Up>` | n, x | Screen line without a count, real line with a count |
| `g/` | x | Start a search limited to the selection |
| `gp` | n | Select the last pasted text |
| `gco` `gcO` | n | Add a commented line below / above |
| `gb` | n | `:ls` then prompt for a buffer number |
| `p` | x | Paste over the selection without the replaced text taking over the register |
| `.` | n | Repeat without moving the cursor (it follows its text if lines are added or removed above; a [count] is passed through). Repeating the `[p` family replays the whole mapping |
| `y` | n, x | Yank without moving the cursor or scrolling (only the mapped keys; `:yank` behaves as usual) |
| `Y` | n | Yank to end of line without moving the cursor or scrolling |
| `<C-w>t` | n | Open the current buffer in a new tab (keeps the original window) |
| `<Esc>` | n | Clear search highlight |
| `<C-n>` `<C-p>` | c | Walk command history unless the wildmenu is open |
| `<Esc><Esc>` `<C-u>` | t | Leave terminal insert mode |
| `[e` `]e` | n, x | Move the current line or selected block up / down (takes a count; the selection stays active; `.` repeats in normal mode) |
| `[p` family | n | See the overview table above; the other bracket pairs there belong to plugins or to Neovim |

Behaviour set by autocmds: files are re-read when changed outside Neovim, the
cursor returns to its last position when a file is reopened, `cursorline` is
shown only in the active window and not in insert mode, splits rebalance when
the terminal is resized, terminals start in insert mode, and yanked text
flashes briefly.

`:Grep {args}` and `:LGrep {args}` run ripgrep, fill the quickfix or location list, and open it.

## Plugins

f2dvim leaves out the plugins on its Exclusion list ([What's left out](#whats-left-out));
their sections apply only when you run the config directly.

For each plugin: what it is for, the mappings it ships with that still apply,
and the mappings this config adds or changes. "Default" means the plugin's own
default is in effect; "custom" means this config sets it.

### Appearance and UI

#### nightfox.nvim (`00-colorscheme.lua`)

Colorscheme. The `carbonfox` variant is active (`background = "dark"` and
`termguicolors` are set in `init.lua`). No mappings.

#### mini.statusline (`99-mini.statusline.lua`)

Statusline. A single global statusline (`laststatus = 3`) showing mode,
relative file path, filetype, progress and location. In markdown and asciidoc
buffers it also shows a word count and estimated reading time. No mappings.

#### Tabline (`init.lua`, `util.tabline`)

Deliberately minimal: it shows only tab numbers, centred and styled from the
colorscheme's `TabLine` groups. Clickable. No mappings.

#### dropbar.nvim (`99-dropbar.lua`)

Breadcrumbs in the winbar (path and symbol under the cursor). Clickable with
the mouse by default.

| Key | Action |
|---|---|
| `<leader>;` | Pick a breadcrumb component interactively (custom) |
| `[;` | Go to the start of the current context (custom) |
| `];` | Select the next context (custom) |

#### snacks.nvim (`99-snacks*.lua`)

A collection of small features from folke. Enabled modules: `bigfile`
(disables heavy features for huge files), `dashboard` (see below), `indent`
(indent guides, also on blank lines; the current scope is mini.indentscope's),
`input` (nicer `vim.ui.input`), `lazygit`, `notifier` (notifications, 5 s
timeout), `picker` (see [Snacks picker](#snacks-picker-99-snackspickerlua) below),
`statuscolumn`, `terminal`, `gh` (see below), `words` (highlights other references of the symbol
under the cursor), and `zen`. Animations are off.

| Key | Action |
|---|---|
| `<leader>ts` | Toggle spell checking |
| `<leader>tw` | Toggle line wrap |
| `<leader>td` | Toggle diagnostics |
| `<leader>th` | Toggle inlay hints |
| `<leader>ti` | Toggle indent guides |
| `<leader>tz` / `gz` | Toggle zoom (current window full-size); also turns off line numbers in that window |
| `<leader>tZ` / `gZ` | Toggle zen mode; also turns off line numbers in that window |
| `<leader>gg` | LazyGit |
| `<leader><Space>` | Dashboard (`q` closes it) |
| `<leader>fp` | [F]ind [P]rojects (TODO: document) |
| `` <leader>` `` | Toggle a terminal below |
| `<leader>tt` / `<C-/>` | Toggle a floating terminal |
| `<C-w>` (terminal mode) | Leave terminal mode and start a window command |

All custom. LazyGit, `just`, `fzj` and the dashboard's `!` commands open in a
floating Snacks terminal that closes when the command exits.

`nvim` with no file opens a dashboard: the Fresh2Dev glasses drawn in box
characters (only when the keys still fit; their temples appear as the height
allows), the keys in the table below, and the Neovim version with the plugin
count and startup time (from `init.lua` to the dashboard). Keys whose tool is
missing are hidden. `<leader><Space>` opens it again later, as a float without a
border.

| Key | Action |
|---|---|
| `n` / `e` | New file (`e` is not listed) |
| `f` | Find files, recent first (`smart`, like `<leader>ff`) |
| `/` | Grep |
| `\` | mini.files, like the global `\` |
| `g` | LazyGit (with `lazygit` installed) |
| `s` / `0` | Sessions, `fzj` (inside zellij, with `fzj` installed; `0` is not listed) |
| `u` | Update plugins (`vim.pack.update()`; hidden when run as the `f2dvim` package) |
| `q` | Close the dashboard; quit Neovim if no other buffer is open |

#### which-key.nvim (`99-which-key.lua`)

Popup listing the keys that can follow a prefix. It appears after 1.5 seconds
of hesitation (immediately for which-key's own plugins: registers, marks and
the other presets). The leader groups in the overview table are registered
here, along with descriptions for the builtin fold jumps `[z` `]z` `zj` `zk`
and a `gr` group for Neovim's default LSP mappings.

| Key | Action |
|---|---|
| `<leader>tk` | Show buffer-local keymaps (custom) |
| `<leader>tK` | Show all keymaps (custom) |

#### colorful-winsep.nvim (`99-colorful-winsep.lua`)

Highlights the borders of the active window. Animation disabled. No mappings.

#### mini.indentscope (`99-mini.indentscope.lua`)

Draws a line along the current indent scope (no animation) and provides indent
text objects and motions, configured to behave like `vim-indent-object`.

| Key | Action |
|---|---|
| `ii` / `ai` | Inside / around the current indent scope (default) |
| `g<` / `g>` | Jump to the top / bottom of the scope (custom, default `[i`/`]i`) |

#### rainbow-delimiters.nvim (`99-rainbow-delimiters.lua`)

Colours matching brackets by nesting depth. Defaults. No mappings.

#### nvim-colorizer.lua (`99-colorizer.lua`)

Shows colour codes in their colour, in `css`, `javascript` and `html` buffers.

| Key | Action |
|---|---|
| `<leader>tc` | Toggle colorizer in the current buffer (custom) |

#### Colour column (`99-smartcolumn.lua`)

Shows the column after `'textwidth'` only while a line exceeds it. Nothing is
hard-coded: Neovim's built-in editorconfig support sets `'textwidth'` from
`max_line_length` (88 for `*.py` in the global `~/.editorconfig`), so files
without one (and special buffers) never show a column. Git commit messages show
it at their own 72. No mappings.

#### visual-whitespace.nvim (`99-visual-whitespace.lua`)

Shows spaces, tabs and line ends inside a visual selection. Defaults. No
mappings.

#### todo-comments.nvim (`99-todo-comments.lua`)

Highlights the plugin's usual keywords in comments (`TODO`, `FIX`/`FIXME`/`BUG`,
`HACK`, `WARN`, `PERF`, `NOTE`/`INFO`, `TEST`, only when followed by a colon);
`TODO` and `NOTE` get custom icons and colours. Signs are off. No mappings;
`:TodoQuickFix` and `:TodoLocList` list the keywords via ripgrep.

#### mini.map (`99-mini.map.lua`)

A minimap on the right edge showing search matches and git diff marks. It
opens automatically in normal file windows and closes when you enter a help,
quickfix, terminal or other special buffer, including the dashboard. A
`CursorHold` autocmd hides it while the cursor is within 20 columns of the right
edge and reopens it otherwise, in file buffers only. No mappings.

#### nvim-hlslens (`99-hlslens.lua`) and vim-asterisk

Shows "match 3 of 12" next to search matches and makes `*`/`#` not jump
immediately.

| Key | Mode | Action |
|---|---|---|
| `n` / `N` | n, x, o | Next / previous match, always forward / backward (custom) |
| `*` / `#` | n, x | Search word under cursor (or selection) forward / backward without moving (custom, via vim-asterisk) |
| `g*` / `g#` | n, x | Same, without word boundaries (custom) |

#### fidget.nvim (`90-lspconfig.lua`)

LSP progress messages in the bottom-right corner. Defaults. No mappings.

#### symbol-usage.nvim (`90-lspconfig.lua`)

Shows reference, definition and implementation counts above classes, methods
and functions. No mappings.

### Editing

#### Delete and change registers (`99-cutlass.lua`)

Makes small delete and change operations stop overwriting the unnamed
register. `x`, `X`, `c`, `C` (normal and visual) and text typed over a
select-mode selection (snippet placeholders) go to the blackhole register. `d`,
`dd` and `D` cut as usual unless the deleted text is only whitespace, in which
case it goes to the blackhole register too.

#### mini.surround (`99-mini.surround.lua`)

Add, delete and change surrounding pairs, mapped like tpope's vim-surround.

| Key | Mode | Action |
|---|---|---|
| `ys{motion}{char}` | n | Add surrounding (custom, default `sa`) |
| `yss{char}` | n | Surround the whole line (custom) |
| `S{char}` | x | Surround the selection (custom) |
| `ds{char}` | n | Delete surrounding (custom, default `sd`) |
| `cs{old}{new}` | n | Change surrounding (custom, default `sr`) |
| `c` as a `{char}` | | Markdown code fence (custom surrounding) |

Find / highlight / update mappings and the `n`/`l` (next / last) suffixes are
disabled. Only the surrounding that covers the cursor is considered
(`search_method = "cover"`), searched within 25 lines.

#### mini.operators (`99-mini.operators.lua`)

Text-transforming operators. Each has a `{prefix}{prefix}` form for the current
line.

| Key | Action |
|---|---|
| `cx{motion}` / `cxx` | Exchange two regions: apply once on each (custom, default `gx`) |
| `X` (visual) | Exchange the selection (custom). Not `cx`: `99-cutlass.lua` maps visual `c`, and a visual `cx` would make `c` wait for `timeoutlen`. This shadows `99-cutlass.lua`'s visual `X` (linewise delete into the blackhole register); use `d` or `D` |
| `gm{motion}` / `gmm` | Multiply (duplicate) text (default) |
| `<leader>p{motion}` / `<leader>pp` | Replace with the register contents (custom, default `gr`) |
| `<leader>P` | Replace to the end of the line, like `D`/`C` (custom, `<leader>p$`) |
| `gs{motion}` / `gss` | Sort: lines when linewise, otherwise the items split on `,`, `;` or whitespace (default) |

The evaluate operator (`g=`) is disabled.
Exchanged and replaced text is reindented linewise.

#### mini.pairs (`99-mini.pairs.lua`)

Inserts the closing bracket or quote when you type the opening one, and `<BS>` /
`<CR>` between a pair delete it / split it over three lines. Tuned like
nvim-autopairs: no pair right before a word or one of `%'["`.$`, no `'` after a
letter, and `<CR>` also splits quotes. Unlike nvim-autopairs there is no bracket
balancing and no filetype rules (Python `"""`, Markdown fences, Rust lifetimes).
Note that blink's own auto-brackets are disabled so only mini.pairs does this.

#### vim-easy-align (`99-easy-align.lua`)

Interactive alignment of tables, assignments, comments.

| Key | Mode | Action |
|---|---|---|
| `ga{motion}` | n | Start EasyAlign on a motion, e.g. `gaip=` (custom) |
| `ga` | x | Start EasyAlign on the selection, e.g. `vipga=` (custom) |

Inside the prompt: a delimiter character, `*` for all occurrences, `<C-x>` for
a regex, `<Enter>` to cycle alignment.

#### guess-indent.nvim (`99-guess-indent.lua`)

Detects the indentation of each file and sets `shiftwidth`/`expandtab` to
match. No mappings.

#### mini.basics (`99-mini.basics.lua`)

Only three pieces are enabled: `<C-hjkl>` window navigation and `<C-Arrow>`
window resizing, relative line numbers in linewise/blockwise visual mode, and
bold window borders.

| Key | Action |
|---|---|
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | Focus the window in that direction (zellij.vim re-maps these; at the edge of Neovim the focus moves to the Zellij pane or tab) |
| `<C-Left>` `<C-Right>` | Decrease / increase window width (takes a count) |
| `<C-Down>` `<C-Up>` | Decrease / increase window height (takes a count) |

#### vim-repeat (`99-repeat.lua`)

Makes `.` repeat plugin mappings (used by the `[p`/`]p` family and vim-sneak).

### Motions and text objects

#### vim-sneak (`99-sneak.lua`)

Two-character jumps.

| Key | Mode | Action |
|---|---|---|
| `s{c}{c}` | n, x | Jump forward to the two characters (custom mapping of the default behaviour) |
| `S{c}{c}` | n | Jump backward |
| `f` `F` `t` `T` | n, x, o | One-character find / till, sneak-enhanced (repeatable across lines) |
| `;` `,` | n, x | Repeat the last sneak / find forward / backward |

`S` is normal-mode only on purpose, because visual `S` belongs to
mini.surround. Neither key is mapped in operator-pending mode, so `ds`/`cs`
and `ys` are never mistaken for an operator plus sneak motion.

#### Edge motion (`99-edgemotion.lua`)

A Lua port of haya14busa/vim-edgemotion.

| Key | Mode | Action |
|---|---|---|
| `gj` | n, x, o | Jump down to the next edge (indent change or blank-line boundary) |
| `gk` | n, x, o | Jump up to the previous edge |

#### mini.ai (`99-mini.ai.lua`)

Better `a`/`i` text objects, with treesitter support. Search radius is 500
lines. `an`/`in`/`al`/`il` (next / last variants) are disabled.

| Key | Action |
|---|---|
| `a(` `i(` and every bracket / quote | Around / inside the pair (default) |
| `ab` `ib` | Any bracket (default) |
| `aq` `iq` | Any quote (default) |
| `af` `if` | Function **call** (default) |
| `aa` `ia` | Function argument (default) |
| `at` `it` | HTML/XML tag (default) |
| `a?` `i?` | Prompted pair (default) |
| `aF` `iF` | Function **definition**, via treesitter (custom) |
| `ae` `ie` | Entire buffer; `ie` skips blank lines at both ends (custom) |
| `av` `iv` | A subword: one part of camelCase, snake_case, kebab-case or UPPER_CASE on the cursor line. `av` takes the separator after it, or before it for the last part (custom). On a separator it picks the next subword |
| `g[` `g]` | Move to the left / right edge of the `a` text object (default) |

#### vim-matchup (`99-matchup.lua`)

Extends `%` to language keywords (`if`/`end`, `<div>`/`</div>`), with the
matching pair highlighted and shown in a popup when off-screen.

| Key | Mode | Action |
|---|---|---|
| `%` | n, x, o | Jump to the matching pair (default). `{count}%` jumps to the count-th pair instead of a percentage of the file (custom, `matchup_motion_override_Npercent = 100`) |
| `g%` | n, x, o | Jump backward through the pair (default) |
| `[%` `]%` | n, x, o | Previous / next outer open / close (default) |
| `z%` | n, x, o | Jump inside the nearest block (default) |
| `a%` `i%` | o, x | Around / inside the matching pair (default) |

#### nvim-treesitter-context (`99-treesitter-context.lua`)

Pins the enclosing function or block signature to the top of the window (one
line, cursor mode).

| Key | Action |
|---|---|
| `[T` | Jump to the context line; with a count, that many levels up (custom) |

#### nvim-ufo (`99-ufo.lua`) with promise-async

Folding driven by treesitter, with indent as fallback. Files open fully
unfolded; a one-character fold column with custom fold glyphs is always shown
(the fold options live in this file, not `init.lua`).

| Key | Action |
|---|---|
| `zR` / `zM` | Open / close all folds (custom, ufo-aware) |
| `zr` | Open all folds except configured kinds (custom, ufo-aware; no kinds are configured, so in practice this equals `zR`) |
| `zm` | Close folds by level (custom, ufo-aware) |
| `zK` | Peek the folded lines under the cursor, or LSP hover if not on a fold (custom) |
| `za` `zo` `zc` `zj` `zk` `[z` `]z` | Builtin fold commands still work |

### Search and navigation

#### Snacks picker (`99-snacks.picker.lua`)

The picker for files, grep, buffers, LSP locations, git objects and more. Also
provides `vim.ui.select`. The preview sits below the list (the `vertical`
layout) except in `vim.ui.select` and the history pickers. Files and grep use
`rg`, include hidden files, follow symlinks and are smart-case; `.gitignore`d
files are left out except by `<leader>fF` and `<leader>fG`. See
[ADR 0002](docs/adr/0002-snacks-picker.md) for why it replaced fzf-lua.

In the grep pickers, anything after ` -- ` in the input is passed to `rg` as
extra arguments. For example, `snacks -- -s` searches case-sensitively, so it
matches `snacks` but not `Snacks`. This only works in grep: the file pickers
fuzzy-match their whole input.

| Key | Mode | Action |
|---|---|---|
| `<leader>F` | n | Resume the last picker |
| `<leader>fa` | n | All pickers |
| `<leader>ff` | n | Files, open buffers and recent files first (`smart`, current directory only) |
| `<leader>fF` | n | Files, including ignored ones |
| `<leader>fg` | n | Live grep |
| `<leader>fG` | n | Live grep, including ignored files |
| `<leader>fg` | x | Grep the selection |
| `gl` | n | Lines in the current buffer |
| `<leader>fb` | n | Buffers |
| `<leader>f"` | n | Registers |
| `<leader>fj` / `<leader>f<C-o>` | n | Jump list |
| `<leader>fm` | n | Marks |
| `<leader>fq` | n | Quickfix list |
| `<leader>fs` | n | Document symbols |
| `<leader>fS` | n | Workspace symbols (live) |
| `<leader>fd` | n | Document diagnostics |
| `<leader>fD` | n | Workspace diagnostics |
| `<leader>ft` | n | TODO comments (todo-comments) |
| `<leader>fn` | n | Notification history |
| `<leader>fu` / `U` | n | Undo history, with a diff preview |
| `<leader>fc` | n | Commands |
| `<leader>fC` | n | Command history |
| `<leader>f/` | n | Search history |
| `<leader>fh` | n | Help tags |
| `<leader>fk` | n | Keymaps |

Inside a picker (Snacks defaults, with these changes; none of its `<A-…>`
defaults are mapped):

| Key | Action |
|---|---|
| `<Enter>` | Open (opens every selected item when several are selected) |
| `<C-o>` / `<C-v>` / `<C-t>` | Open in split below (custom, replaces `<C-s>`) / vsplit / tab |
| `<C-g>` | Switch between live grep and filtering the results |
| `<C-/>` | Toggle the preview (custom) |
| `<F1>` | Help (custom; `?` in the list) |
| `<C-f>` `<C-b>`, `<S-Down>` `<S-Up>` | Scroll the preview (`<S-…>` custom) |
| `<Tab>` | Select multiple items |
| `<C-q>` | Send the selected (or all) items to quickfix |

#### grug-far.nvim (`99-grug-far.lua`)

Find and replace across files, using `rg`. Opens at the bottom of the screen
with search, replace, files-filter, flags and paths inputs; results update as
you type. The paths input also accepts `<buflist>` and `<qflist>`, so it can
target what `:Grep` or a picker's `<C-q>` found. The buffer is transient
(unlisted, and deleted once its window closes). Editing result lines and
syncing them back to the files is disabled (custom): changes go through
Replace or Apply.

| Key | Mode | Action |
|---|---|---|
| `<leader>fr` | n | Find and replace |
| `<leader>fr` | x | Find and replace the selection (cursor starts in Replace) |
| `<leader>fR` | n, x | Same, in a new tab |

In the grug-far buffer (custom; `g?` lists them). With `<localleader>` on
`<Space>`, none of these may equal a global `<leader>` map, or it would shadow
it; `<localleader>qq` deliberately takes over Quit smart.

| Key | Action |
|---|---|
| `<localleader>R` | Replace all matches |
| `<localleader>j` / `<localleader>k` | Apply the next / previous match only |
| `<Enter>` | Go to the location, in the window above |
| `K` | Preview the location in a float |
| `<C-q>` | Send the results to quickfix |
| `<localleader>h` / `<localleader>H` | Open / add to history |
| `<F5>` | Refresh |
| `<localleader>A` | Abort a running search or replace |
| `<localleader>c` | Show the `rg` command |
| `<localleader>qq` | Close |
| `<Tab>` / `<S-Tab>` | Next / previous input |

### Files, buffers, windows

#### mini.files (`99-mini.files.lua`)

Column-style file explorer with a preview pane that edits the filesystem like
a buffer: rename by editing a line, create by adding one, delete by deleting
one, then synchronise. Also replaces netrw for directory arguments. Renames and
moves are reported to the language servers (`Snacks.rename`), so a server that
supports it updates imports and other references to the file.

| Key | Action |
|---|---|
| `\` | Open at the working directory, or close if open (custom) |
| `\|` | Open at the current file with the working-directory branch expanded, or close if open (custom) |

Inside the explorer (custom set, overrides the defaults shown in parentheses):

| Key | Action |
|---|---|
| `L` | Go into the directory / open file (default `l`) |
| `<CR>` | Go in; on a file, open it and close the explorer (default `L`) |
| `<BS>` | Go out to the parent (default `h`; the default `H` "go out plus" is unmapped) |
| `<C-o>` / `<C-v>` | Open the file in a horizontal / vertical split (custom) |
| `<leader>w` | Synchronise (apply) changes (default `=`) |
| `<F5>` | Reset (default `<BS>`) |
| `@` | Reveal the working directory |
| `M` / `'` | Set / go to a mark |
| `<` / `>` | Trim columns on the left / right |
| `g?` | Help |
| `q` | Close |

Deletion is permanent (no trash).

#### mini.bufremove (`99-mini.bufremove.lua`)

Delete buffers without closing their windows, plus the quit family built on
top of it. The bulk deletes (`:QuitHidden`, `:QuitOther`, `:QuitAll`) only
touch regular listed buffers, so hidden terminals and plugin buffers survive,
and modified buffers are skipped and reported unless the command gets a `!`.
`:QuitGit` is the opposite: it targets exactly the fugitive, flog and git
buffers and closes their windows.

| Key | Action |
|---|---|
| `<leader>w` / `<leader>W` | Write / write all |
| `<leader>x` / `<leader>qq` | Quit smart: close a floating window outright; otherwise close the window if the buffer is shown in another window or if every other buffer is already visible in this tab, else delete the buffer |
| `<leader>qe` / `<leader>qE` | Delete the buffer, keep the window (`:Bdelete` / `:Bdelete!`) |
| `<leader>qs` / `<leader>qS` | Close the window / keep only this window |
| `<leader>qt` | Close the tab |
| `<leader>qu` | Edit the alternate buffer |
| `<leader>qo` | Delete hidden buffers (`:QuitHidden`); the alternate buffer counts as hidden, so `<leader>qu` stops working right after |
| `<leader>qO` | Close other tabs and windows, then delete hidden buffers (`:QuitOther`) |
| `<leader>qa` / `<leader>qA` | Delete all buffers (`:QuitAll` / `:QuitAll!`) |
| `<leader>qg` | Delete git buffers and close their windows (`:QuitGit`) |

#### vim-eunuch (`99-eunuch.lua`)

Filesystem commands: `:Remove`/`:Delete`, `:Unlink`, `:Move`, `:Copy`,
`:Duplicate`, `:Chmod`, `:Mkdir`, `:SudoWrite`, `:SudoEdit`, `:Wall`, `:Cfind`,
`:Lfind` and the rest of vim-eunuch's set. All of the plugin's own mappings
(`g:eunuch_no_maps`) are disabled.

`:Rename` is replaced by a Snacks one, so language servers see the rename and
update imports. It takes a name relative to the file's directory, or prompts when
given none.

#### nvim-fundo (`99-fundo.lua`) with promise-async

Makes persistent undo reliable across external changes to a file (it archives
undo files, capped at 512 MB). No mappings.

### Git

#### vim-fugitive (`99-fugitive.lua`) with vim-flog

Git inside Neovim. `:Git` (abbreviated `:g` / `:git`) runs any git command;
`:Git` alone opens the status buffer. vim-flog draws the commit graph; without
it, the status views fall back to `git log --graph --oneline --decorate`. On
startup the working directory becomes the repository root.

| Key | Action |
|---|---|
| `<leader>gt` | Status buffer with the commit graph, in a new tab (then presses `i` to expand the first diff) |
| `<leader>go` | Same, as the only window |
| `<leader>gO` | Same, after deleting all buffers |
| `<leader>gb` | Blame (`:Git blame -s`) |
| `<leader>gl` / `<leader>gL` | Log graph for the current branch / all branches |
| `<leader>gr` | File revisions in the quickfix list (`:1,$GcLog!`); in visual mode, for the selection |
| `<leader>ge` | `:Gedit` (back to the working-tree version) |
| `<leader>gw` / `<leader>gW` | `:Gwrite` / `:Gwrite!` (stage, or overwrite) |
| `<leader>gp` / `<leader>gP` | Push / force push |

Inside fugitive buffers (custom additions on top of fugitive's defaults):

| Key | Buffer | Action |
|---|---|---|
| `q` | status, blame, graph | Close |
| `q` | git output | Close |
| `<CR>` | blame | Open the commit in a split |
| `O` | status | Open in a vertical split (default opens a tab) |
| `dt` | status | Diff the file under the cursor in a new tab |

Useful fugitive defaults in the status buffer: `s` / `u` stage / unstage, `-`
toggle, `=` inline diff, `cc` commit, `ca` amend, `dv` vertical diff, `X`
discard, `g?` help. In the flog graph: `<CR>` opens the commit, `a` toggles
all branches, `u` refreshes, `y<C-g>` yanks the hash, `gq` quits, `g?` help.

#### gitsigns.nvim (`99-gitsigns.lua`)

Change marks in the sign column and line numbers, and hunk navigation.

| Key | Mode | Action |
|---|---|---|
| `]c` / `[c` | n | Next / previous hunk with a preview (falls back to diff-mode `]c` in diffs) |

All custom; gitsigns ships no mappings.

#### diffview.nvim (`99-diffview.lua`)

Side-by-side diffs for the working tree, revisions and file history, plus a
merge tool (`diff4_mixed` layout). The file panel is a flat list 25 columns
wide and is closed every time a view opens; `<C-\>` brings it back. This
config disables the plugin's default keymaps and declares its own full set;
the ones that differ from the defaults are marked.

| Key | Action |
|---|---|
| `<leader>gd` | `:DiffviewOpen` (working tree against index) |
| `<leader>gR` | `:DiffviewFileHistory %` (history of the current file) |

In the diff view and the panels (the staging, restore, log and refresh keys
exist only in the file panel; `X` and `L` also in the history panel):

| Key | Action |
|---|---|
| `]q` / `[q` (also `]a` / `[a` in the file panel) | Next / previous file (custom; default `<Tab>` / `<S-Tab>`) |
| `<C-\>` | Toggle the file panel (custom; default `<leader>b`) |
| `gf` | Open the file in a new tab (custom; default opens in place) |
| `[c` / `]c` | Previous / next conflict (custom; default `[x` / `]x`) |
| `<leader>co` `ct` `cb` `ca` | Choose ours / theirs / base / all for the conflict |
| `<leader>cO` `cT` `cB` `cA` | Same, for the whole file |
| `dx` / `dX` | Delete the conflict region / all conflict regions |
| `2do` / `3do` (`1do` in 4-way) | Take the hunk from ours / theirs (base) |
| `-` | Stage / unstage the entry |
| `X` | Restore the entry |
| `L` | Commit log |
| `<F5>` | Refresh (custom; default `R`) |
| `dt` (history panel) | Open the entry in a diffview |
| `y` (history panel) | Copy the commit hash |
| `g!` (history panel) | Options |
| `j`/`k`, `<CR>`/`o`/`l`, `h`, `zo`/`zc`/`za`/`zR`/`zM`, `<C-b>`/`<C-f>` | Move, open, collapse, fold, scroll |
| `g?` | Help for the current panel |

The default multi-select (`w`, `C`, `H`), staging (`s`, `S`, `U`), listing
style (`i`, `f`) and layout-cycling (`g<C-x>`) keys are intentionally not
bound.

#### Conflict hunks (`99-conflict-marker.lua`)

| Key | Action |
|---|---|
| `]x` / `[x` | Next / previous conflict hunk; a hunk needs all of its `<<<<<<<`, `=======` and `>>>>>>>` lines. From inside a hunk, `[x` goes to the hunk before it |
| `<leader>co` `ct` `cb` `ca` | Replace the conflict under the cursor, markers included, with ours / theirs / base / all three |
| `<leader>cO` `cT` `cB` `cA` | Same, for every conflict in the file |

The choose maps read the markers, so they need no diff: they work in fugitive's
3-way diff, in a plain buffer, and in diffview (whose own maps of the same name
do the same). Base needs git's `merge.conflictStyle` set to `diff3` or `zdiff3`;
without it `cb` / `cB` report an error and change nothing. To take a diff hunk
instead of a marker block, use fugitive's `d2o` / `d3o` in its 3-way diff, or
diffview's `2do` / `3do`.

Resolving conflicts with fugitive: `:Git mergetool` loads the conflicts into the
quickfix list. On each file, open the 3-way diff with `:Gvdiffsplit!` if you want
it, go to a conflict with `]x`, choose with `<leader>co` / `ct`, then `:w` and
`<leader>gw` (`:Gwrite`) to mark the file resolved. `]q` goes to the next
conflict.

#### lazygit (snacks)

`<leader>gg` opens lazygit in a floating terminal; see snacks above.

#### GitHub (snacks, `99-snacks.gh.lua`)

Issue and pull request pickers through the `gh` CLI; `<CR>` on an item lists its
actions (open, comment, review, checkout, merge, ...).

| Key | Action |
|---|---|
| `<leader>ghi` / `<leader>ghI` | GitHub issues (open / all) |
| `<leader>ghp` / `<leader>ghP` | GitHub pull requests (open / all) |

### LSP, completion, formatting, syntax

#### nvim-lspconfig (`90-lspconfig.lua`)

Provides the server definitions; Neovim's own `vim.lsp.config` / `vim.lsp.enable`
start them. Servers must already be installed. Neovim's default LSP mappings
(`K` hover, `grn` rename, `gra` code action, `grr` references, `gri`
implementation, `grt` type definition, `gO` document symbols, insert-mode
`<C-s>` signature help) apply; the config routes the list-producing ones
through the Snacks picker. All are buffer-local and appear in which-key with an
`LSP:` prefix.

| Key | Mode | Action |
|---|---|---|
| `gd` | n | Definitions (picker) |
| `gD` | n | Declaration |
| `grr` | n | References (picker) |
| `gri` | n | Implementations (picker) |
| `grt` | n | Type definitions (picker) |
| `gO` | n | Document symbols (picker); `<leader>fs` from `99-snacks.picker.lua` is the same picker, `<leader>fS` the workspace one |
| `grI` / `grO` | n | Incoming / outgoing calls (picker) |
| `<C-s>` | n | Signature help |
| `[d` / `]d` | n | Previous / next diagnostic, opening a float (unless `virtual_lines` is on; it is off) |
| `K` `grn` `gra` | n | Neovim defaults (hover, rename, code action) |

Symbol references under the cursor are highlighted after a short pause.
Diagnostics show as virtual text, sorted by severity, underlined from warning
level up.

Server notes: the Python type checker is `ty`, with `possibly-unresolved-reference`
raised to an error; `ruff` has organise-imports off; `gopls` enables staticcheck and gofumpt; `rust_analyzer` uses its
defaults; `bashls` also covers zsh; `tombi` serves TOML diagnostics, hover, definitions and code actions.

Formatting: `dprint lsp` is the only formatter. Every other server has its
formatting capabilities removed on attach (and may not register them
dynamically), so `gq` and `vim.lsp.buf.format()` reach dprint alone. It uses the
project's `dprint.json` or, outside one, the global
`~/.config/dprint/dprint.jsonc`, and formats on save with a 1 second timeout.

| Command | Action |
|---|---|
| `:FormatDisable` / `:FormatEnable` / `:FormatToggle` | Format on save for the current buffer |

#### blink.cmp (`99-blink.cmp.lua`)

Completion. Sources: LSP, file paths (relative to the working directory),
buffer words, and lazydev in Lua buffers. Nothing is preselected; the
documentation window appears after half a second; auto-brackets are off
(mini.pairs handles them); signature help shows while typing arguments.
Disabled in mini.files, Snacks picker prompts and fugitive buffers.

Insert mode (`default` preset plus custom `<Tab>` / `<CR>`):

| Key | Action |
|---|---|
| `<C-n>` / `<C-p>` or `<Down>` / `<Up>` | Next / previous item |
| `<CR>` | Accept the selected item (custom) |
| `<Tab>` | Accept if an item is selected, else jump forward in a snippet (custom) |
| `<S-Tab>` | Snippet backward |
| `<C-y>` | Select and accept |
| `<C-e>` | Cancel |
| `<C-Space>` | Show the menu / toggle documentation |
| `<C-b>` / `<C-f>` | Scroll documentation |
| `<C-k>` | Toggle signature help |

Command line (`cmdline` preset plus custom keys): the menu does not pop up on
its own, but ghost text previews the first match.

| Key | Action |
|---|---|
| `<Tab>` / `<S-Tab>` | Show and cycle completions |
| `<Down>` / `<Up>` | Next / previous (custom) |
| `<Left>` / `<Right>` | Move the cursor as usual (custom, no completion) |

`/` and `?` complete from buffer words; `:` completes commands.

#### nvim-treesitter (`90-treesitter.lua`)

Syntax highlighting and indentation from treesitter parsers, using the
plugin's `main` branch API. A base set of parsers is installed at first start
(bash, c, css, go, html, json, lua, markdown, python, sql, typescript, yaml,
git filetypes and more); any other parser, `rust` included, is installed
automatically the first time its filetype is opened. `gitcommit` is left out
of the base set because its parser is very slow to compile, but it is not
excluded: the first commit buffer you open still triggers the build. Folds come
from nvim-ufo, not treesitter. No mappings. `:TSUpdate` runs automatically
after plugin updates.

#### lazydev.nvim (`ftplugin/lua_lazydev.lua`)

Loaded for Lua buffers only. Teaches `lua_ls` about the Neovim runtime and
`vim.uv` types lazily, so editing this config gets completions without a slow
workspace scan. Also feeds blink's `lazydev` source.

### Integrations

#### zellij.vim (`99-zellij.lua`)

Seamless `<C-hjkl>` navigation between Neovim windows and Zellij panes; when
there is no window in that direction the focus moves to the Zellij pane (or
tab, with the `move_focus_or_tab` setting on). Outside Zellij it falls back to
plain window navigation. Commands: `:ZellijNewPane`, `:ZellijNewPaneSplit`,
`:ZellijNewPaneVSplit`, `:ZellijNewTab`, `:ZellijNavigate{Up,Down,Left,Right}`.
Pair it with zellij-autolock so Zellij keybindings do not intercept Neovim's.

### Filetype-specific

#### Markdown (`ftplugin/markdown.lua`)

**markdown-plus.nvim** replaces vim-markdown-toc, markdown-toggle.nvim and the
old hand-written link helper. Its default keymaps are off (they collide with
the `<leader>t` group and `]b`, since `<localleader>` is also
`<Space>`); everything is mapped buffer-locally under `<localleader>m`, which
which-key shows as a group in markdown buffers.

Editing keys that act only in context and otherwise hand the key back to blink,
mini.pairs or the native behaviour: `<CR>` continues a list, `<Tab>`/`<S-Tab>`
indent and outdent an item, `<BS>` removes an empty marker, `<A-CR>` continues
the item's content on a new line, `o`/`O` open a new item, `<A-h/j/k/l>` move
between table cells in insert mode. `<C-t>` keeps its
insert-mode indent and `gd` belongs to the LSP.

| Keys | Action |
|---|---|
| `<localleader>mb` `mi` `mS` `` m` `` `m=` `mu` `mF` | toggle bold, italic, strikethrough, inline code, highlight, underline; clear formatting (normal and visual) |
| `<localleader>me` (visual) | escape / unescape markdown punctuation |
| `<localleader>mx` | toggle checkbox (normal and visual) |
| `<localleader>ml{u,t,n,N,l,L,p,P,c}` | set list type: `-`, task, `1.`, `1)`, `a.`, `A.`, `a)`, `A)`, clear |
| `<localleader>mr` | renumber ordered lists |
| `<localleader>m1`…`m6` `m+` `m-` `ms` | set heading level, promote, demote, toggle ATX/setext |
| `[[` `]]` | previous / next heading |
| `<localleader>mTg` `mTu` `mTo` | generate / update the TOC between `<!-- TOC -->` fences (as in this README, H2 and H3); open a navigable TOC window (`:Toc`, `:Toch`, `:Toct`) |
| `<localleader>mk` | insert a link (normal) or turn the selection into one (visual) |
| `<localleader>me` (normal) `ma` `mp` `mR` `mI` | edit link under cursor, auto-link a bare URL, paste the clipboard URL as a link (fetches the page title over HTTP), convert to reference / inline style |
| `<localleader>mg` `mG` `mA` | insert image / selection to image, edit image, toggle link ⇄ image |
| `<localleader>mc` `mC` `[f` `]f` | insert or wrap a fenced code block, change its language, jump between fences |
| `<localleader>mq` `mQ{i,t,c,b}` | toggle blockquote; insert callout, cycle its type, blockquote ⇄ callout |
| `<localleader>mh` `mH` | insert a horizontal rule, cycle its style |
| `<localleader>mf{i,e,d,g,r,n,p,l}` | footnotes: insert, edit, delete, go to definition / reference, next, previous, list |
| `<localleader>mt…` | tables: `c` create, `f` format, `n` normalize, `t` transpose, `e` edit cell in a popup, `a` cell alignment, `i{r,R,c,C}` insert row/column, `d{r,c}` delete, `m{h,j,k,l}` move, `s{a,d}` sort, `y{r,c}` duplicate, `v{i,x}` CSV in/out, `w`/`W`/`b`/`x` wrap, unwrap, `<br>`, clear cell |

#### Lua

lazydev, see above.

### Libraries

Installed because another plugin requires them; no user-facing behaviour:
**mini.icons** (icons for the Snacks picker, mini.statusline, mini.files; mocks nvim-web-devicons for the rest),
**plenary.nvim** (todo-comments), **promise-async** (ufo, fundo).

## User commands

| Command | Defined in | Action |
|---|---|---|
| `:Grep` `:LGrep` | init.lua | ripgrep into the quickfix / location list |
| `:Bdelete[!] [buf]` `:Bwipeout[!] [buf]` | mini.bufremove | Delete / wipe a buffer by number or name, keeping windows |
| `:QuitSmart[!]` `:QuitHidden[!]` `:QuitOther[!]` `:QuitAll[!]` `:QuitGit[!]` | mini.bufremove | See the quit family above |
| `:FormatEnable` `:FormatDisable` `:FormatToggle` | 90-lspconfig | dprint format on save for this buffer |
| `:Git` `:Gedit` `:Gwrite` `:Gdiffsplit` `:GcLog` … | fugitive | Git |
| `:Flog` `:Flogsplit` | flog | Commit graph |
| `:DiffviewOpen` `:DiffviewFileHistory` `:DiffviewClose` | diffview | Diffs |
| `:TodoQuickFix` `:TodoLocList` | todo-comments | List `TODO:` comments |
| `:GrugFar` `:GrugFarWithin` | grug-far | Find and replace across files / within the visual range |
| `:Toc` `:Toch` `:Toct` | markdown-plus (markdown buffers) | Navigable table of contents in a split / tab |
| `:ColorizerToggle` | colorizer | Colour preview |
| `:Remove` `:Move` `:Rename` `:Chmod` `:Mkdir` `:SudoWrite` … | eunuch | Filesystem (`:Rename` is Snacks) |
| `:ZellijNewPane` `:ZellijNewTab` … | zellij.vim | Zellij panes |
| `:TSUpdate` `:TSInstall` | treesitter | Parsers |

Command-line abbreviations: `grep`, `lgrep`, `g`, `git`.

## Extending the config

- **Add a plugin**: create `plugin/99-<name>.lua` with a `vim.pack.add` call
  and the configuration. List every plugin the file needs, even if another
  file also lists it. Give every mapping a `desc`, and register any new
  `<leader>` prefix in `plugin/99-which-key.lua`.
- **Add a language server**: add an entry to the `servers` table in
  `plugin/90-lspconfig.lua` and install the binary.
- **Format a new filetype**: add it to the `dprint` entry's `filetypes` in
  `plugin/90-lspconfig.lua` and give dprint a plugin for it.
- **Add a build step** after install or update: extend the `PackChanged`
  autocmd at the bottom of `init.lua`.
- **Defer a plugin to a filetype**: put it in `ftplugin/<ft>.lua` (or
  `ftplugin/<ft>_<name>.lua` when the filetype already has a file) behind a
  `vim.g.loaded_<...>_config` guard, as `ftplugin/markdown.lua` and
  `ftplugin/lua_lazydev.lua` do.
- Before committing, run `stylua config` and the check commands under
  [Working on the config](#working-on-the-config).

`CLAUDE.md` documents the conventions and the deliberate deviations in more
depth.

## Working on the config

On a machine that can reach GitHub, you can run `config/` as a plain Neovim config
instead of through f2dvim. Link it from the project root, then start Neovim:

```sh
just link        # refuses to replace a real ~/.config/nvim; move that aside first
nvim             # first start installs every plugin, then runs :TSUpdate
```

The first start is slow: `vim.pack` clones every plugin synchronously.
Subsequent starts are fast (`vim.loader` caches compiled Lua).

`~/.config/nvim` is a symlink into the checkout, so edits to `config/` take
effect on the next start, and `vim.pack` writes `nvim-pack-lock.json` straight
into the checkout: plugin installs and updates show up in `git diff`.

To try the config next to an existing one, link it under another name and point
`NVIM_APPNAME` at it:

```sh
NVIM_APPNAME=nvim-dev just link   # links ~/.config/nvim-dev
NVIM_APPNAME=nvim-dev nvim
```

`just update` and `just prune` maintain the plugins (see
[Building from source](#building-from-source)). Format Lua with `stylua config` from the
project root, which picks up the root `.stylua.toml`. To check a change:

```sh
cd config
nvim --headless -c 'qa'                                                # startup errors surface here
nvim --headless -c 'e ../README.md' -c 'e init.lua' -c 'qa'            # one buffer per ftplugin, so those plugins reach the lockfile
nvim --headless -c 'lua vim.pack.update(nil, {offline=true})' -c 'qa'  # plugin state
stylua --check --search-parent-directories .                           # formatting
```

On the Home machine, mise installs Neovim, the tools and the language servers from
fresh2dev's dotfiles (their global mise config, `home/.config/mise/config.toml`). Add a
new dependency there, not here.

## Building from source

f2dvim is built from [`config/`](config) in this project, using the
plugins that Neovim installed there. You need `uv` and `just` (`mise install` provides
both, from `mise.toml`), and `gum` for `just prune`. From this directory:

| Recipe | Effect |
|---|---|
| `just link` | Symlink `config/` to `~/.config/${NVIM_APPNAME:-nvim}`, refusing to replace a real directory |
| `just build` | Build the sdist and wheel into `dist/`, versioned from the latest git tag |
| `just test` | Run the tests, including a headless smoke test of a freshly built wheel (skipped without `nvim` or installed plugins, as in CI) |
| `just update` | Update the config's plugins and `nvim-pack-lock.json` |
| `just prune` | Delete installed plugins that no plugin file declares, after confirming |
| `just lint`, `just check-types`, `just check-docstrings` | The checks CI runs |

`[tool.f2dvim]` in `pyproject.toml` controls the build:

- `config-dir` is the Neovim config to package.
- `exclude` is the Exclusion list: plugin files to leave out.
- `licenses` gives SPDX ids for plugins that have no license file.

The build copies the config's runtime files, minus excluded plugin files. Then it
exports each plugin that the remaining files declare, with `git archive` at its
`nvim-pack-lock.json` revision. It fails if a plugin isn't locked, isn't installed, or
has no license.

Only wheels are published. An sdist couldn't be rebuilt without the installed plugins.

### Releasing

Versions come from unprefixed git tags (`0.1.0`). Release from the Home machine, on a
clean tree, since CI has no plugins to build with:

```sh
just test
git tag 0.1.0
just clean build        # clean empties dist/, so only this version is uploaded
uv publish dist/*.whl   # the wheel only
git push origin 0.1.0   # runs the checks, then publishes the docs
```

Terms used in the code are defined in [GLOSSARY.md](GLOSSARY.md).

## License

MIT for f2dvim's own code. Each bundled plugin keeps its own license, which ships
inside its directory in the wheel.
