# f2dvim runs the config in place inside the Python package

Work machines cannot reach GitHub, so the Neovim config and its Plugins are shipped as
the `f2dvim` PyPI package. Its launcher runs `nvim` with `NVIM_APPNAME=f2dvim`, `-u`
pointing at the packaged `init.lua`, the packaged config and Plugins prepended to
`runtimepath`/`packpath`, and a stub that replaces `vim.pack.add` with `packadd`. The
config stays read-only inside the package and identical to the Home machine's; only
Neovim's state, data and cache dirs are written, under the `f2dvim` app name.

## Considered Options

- **Copy the config into `~/.config/nvim` and Plugins into vim.pack's directory**:
  rejected. The installed copy drifts from the package and must be re-synced after
  every upgrade.
- **Point `XDG_CONFIG_HOME` into the package**: rejected. Every child process (git,
  lazygit) would read its config from the package. `NVIM_APPNAME` cannot hold an
  absolute path, so `-u` plus `runtimepath` is the only way to keep the config in place.
