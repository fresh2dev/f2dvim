set positional-arguments

wheel := "dist/f2dvim-" + `uv version --short` + "-py3-none-any.whl"
nvim_appname := env("NVIM_APPNAME", "nvim")

# List recipes
default:
    @just --choose

# Build the f2dvim wheel into dist/
build:
    rm -f "{{ wheel }}"
    uv build --wheel

# Build the wheel, then run the tests against it (including the headless smoke test)
test *args: build
    F2DVIM_WHEEL="{{ wheel }}" uv run pytest "$@"

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
    stale=$(uv run -q python bundle.py stale)
    [ -n "$stale" ] || { echo "No Stale Plugins."; exit 0; }
    echo "$stale"
    gum confirm "Delete these Stale Plugins?" || exit 0
    names=$(printf '"%s",' $stale)
    env -u NVIM_APPNAME nvim --headless -c "lua vim.pack.del({ ${names%,} })" -c qa

# Release f2dvim: checklist, version bump, test, then commit, tag and publish (no push)
release:
    #!/usr/bin/env bash
    set -euo pipefail
    branch=$(git branch --show-current)
    if [ -n "$(git status --porcelain -- .)" ]; then
        echo "Commit or stash changes in f2dvim/ first." >&2
        exit 1
    fi
    if [ "$branch" = main ]; then
        echo "Release from a branch other than main." >&2
        exit 1
    fi
    current=$(uv version --short)
    last_tag=$(git describe --tags --abbrev=0 --match 'f2dvim-v*' 2>/dev/null || echo none)
    gum style --bold "f2dvim $current (last tag: $last_tag, branch: $branch)"

    bump=$(gum choose --header "Version bump" patch minor major exact)
    if [ "$bump" = exact ]; then
        version_args=("$(gum input --prompt "Version: " --placeholder "$current")")
    else
        version_args=(--bump "$bump")
    fi
    uv version "${version_args[@]}" --dry-run
    new=$(uv version "${version_args[@]}" --dry-run --short)

    echo "Exclusion list:"
    uv run -q python bundle.py exclude | sed 's/^/  /'
    echo "Plugins packaged: $(uv run -q python bundle.py plugins | wc -l | tr -d ' ')"
    gum confirm "Release f2dvim $new with this Exclusion list?"

    # The tree was clean, so reverting the version change is a plain checkout.
    trap 'git checkout -q -- pyproject.toml uv.lock; echo "Release aborted; version reverted." >&2' EXIT
    uv version "${version_args[@]}" -q
    just test -q
    gum confirm "Commit, tag f2dvim-v$new and publish to PyPI?"
    git commit -q -m "release: f2dvim v$new" -- pyproject.toml uv.lock
    trap - EXIT
    git tag -a "f2dvim-v$new" -m "f2dvim v$new"
    uv publish "dist/f2dvim-$new-py3-none-any.whl" || {
        echo "Publish failed; the release commit and tag exist. Retry: uv publish dist/f2dvim-$new-py3-none-any.whl" >&2
        exit 1
    }
    echo "Released f2dvim $new. Nothing was pushed: git push && git push origin f2dvim-v$new"
