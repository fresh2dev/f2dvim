nvim_appname := env("NVIM_APPNAME", "nvim")

# ─────────────────────────────────────────────────────────────────────────────
# Tools
# ─────────────────────────────────────────────────────────────────────────────

git_cliff := '''
    uvx --from 'git-cliff==2.*' \
    -- git-cliff'''

# ─────────────────────────────────────────────────────────────────────────────
# Modules (present only when enabled for this project)
# ─────────────────────────────────────────────────────────────────────────────

import? 'python.just'
import? 'docs.just'

# ─────────────────────────────────────────────────────────────────────────────
# Default
# ─────────────────────────────────────────────────────────────────────────────

[positional-arguments]
default:
    @ just --choose

# ─────────────────────────────────────────────────────────────────────────────
# Core
# ─────────────────────────────────────────────────────────────────────────────

[positional-arguments]
changelog:
    {{ git_cliff }} --unreleased --prepend CHANGELOG.md

[positional-arguments]
format *paths:
    dprint fmt "$@"

# ─────────────────────────────────────────────────────────────────────────────
# Project-specific
# ─────────────────────────────────────────────────────────────────────────────

# Symlink config/ to ~/.config/${NVIM_APPNAME:-nvim}, refusing to replace a real directory
link _link_dest=(home_directory() / ".config" / nvim_appname):
    @[ ! -e "{{ _link_dest }}" ] || [ -L "{{ _link_dest }}" ] || { echo "{{ _link_dest }} exists and is not a symlink; move it aside first." >&2; exit 1; }
    mkdir -p "{{ parent_directory(_link_dest) }}"
    ln -sfn "{{ justfile_directory() }}/config" "{{ _link_dest }}"

# Update every Plugin and the lockfile of the Home machine's config, without review
update:
    env -u NVIM_APPNAME nvim --headless -c 'lua vim.pack.update(nil, { force = true })' -c qa

# Delete Stale Plugins (locked or installed, declared by no Plugin file), after confirming
prune:
    #!/usr/bin/env bash
    set -euo pipefail
    stale=$(uv run -q python scripts/bundle.py stale)
    [ -n "$stale" ] || { echo "No Stale Plugins."; exit 0; }
    echo "$stale"
    gum confirm "Delete these Stale Plugins?" || exit 0
    names=$(printf '"%s",' $stale)
    env -u NVIM_APPNAME nvim --headless -c "lua vim.pack.del({ ${names%,} })" -c qa
