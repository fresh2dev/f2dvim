"""Build-time logic for f2dvim: which Plugins the config declares, and staging them.

Runs on the Home machine only (from the build hook and the justfile); it is not part
of the installed package.
"""

import io
import json
import os
import re
import shutil
import subprocess
import tarfile
import tomllib
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote

# Config entries Neovim loads at runtime; everything else (docs, lockfile, formatter
# config) stays out of f2dvim.
RUNTIME_ENTRIES = (
    "init.lua",
    "lua",
    "plugin",
    "ftplugin",
    "after",
    "lsp",
    "colors",
    "syntax",
    "indent",
    "ftdetect",
    "autoload",
    "queries",
    "snippets",
    "spell",
)
_LICENSE_FILE = re.compile(r"(?i)^(licen[cs]e|copying|unlicense)")

# Lua block comments (`--[[ ... ]]`, `--[==[ ... ]==]`) and line comments.
_BLOCK_COMMENT = re.compile(r"--\[(=*)\[.*?\]\1\]", re.DOTALL)
_LINE_COMMENT = re.compile(r"--.*")
# shortcut: any quoted https URL outside a comment counts as a Plugin source; parse
# `vim.pack.add` calls properly if Plugin files ever quote other URLs.
_QUOTED_URL = re.compile(r"""["'](https://[^"'\s]+)["']""")


def plugin_name(url: str) -> str:
    """Name a Plugin the way `vim.pack` does: the last URL segment, minus `.git`."""
    return url.rstrip("/").removesuffix(".git").rsplit("/", 1)[-1]


def declared_plugins(sources: Iterable[str]) -> dict[str, str]:
    """Map each Plugin declared in the given Plugin-file contents to its source URL."""
    declared: dict[str, str] = {}
    for source in sources:
        code = _LINE_COMMENT.sub("", _BLOCK_COMMENT.sub("", source))
        for url in _QUOTED_URL.findall(code):
            declared[plugin_name(url)] = url
    return declared


def plugin_files(config_dir: Path) -> list[Path]:
    """Every Plugin file in the config, relative to `config_dir`."""
    return sorted(
        path.relative_to(config_dir)
        for subdir in ("plugin", "ftplugin")
        for path in (config_dir / subdir).rglob("*")
        if path.suffix in {".lua", ".vim"}
    )


class BuildError(Exception):
    """The config or the Home machine's Plugin install cannot produce f2dvim."""


@dataclass(frozen=True)
class Settings:
    """The `[tool.f2dvim]` table of pyproject.toml."""

    config_dir: Path
    exclude: frozenset[Path]
    licenses: dict[str, str]

    @classmethod
    def load(cls, project_dir: Path) -> "Settings":
        with (project_dir / "pyproject.toml").open("rb") as file:
            table = tomllib.load(file)["tool"]["f2dvim"]
        return cls(
            config_dir=(project_dir / table["config-dir"]).resolve(),
            exclude=frozenset(map(Path, table.get("exclude", []))),
            licenses=table.get("licenses", {}),
        )

    def lockfile(self) -> dict[str, dict[str, str]]:
        """The config's `nvim-pack-lock.json` entries, by Plugin name."""
        lock = json.loads((self.config_dir / "nvim-pack-lock.json").read_text())
        return lock["plugins"]

    def declared(self, files: Iterable[Path]) -> dict[str, str]:
        return declared_plugins((self.config_dir / f).read_text() for f in files)

    def kept_plugin_files(self) -> list[Path]:
        """Plugin files not on the Exclusion list."""
        files = plugin_files(self.config_dir)
        if unknown := self.exclude - set(files):
            names = ", ".join(sorted(map(str, unknown)))
            raise BuildError(f"Exclusion list names no such Plugin file: {names}")
        return [f for f in files if f not in self.exclude]

    def packaged_plugins(self) -> dict[str, str]:
        """Plugins declared by the kept Plugin files."""
        return self.declared(self.kept_plugin_files())

    def stale_plugins(self) -> list[str]:
        """Stale Plugins: locked or installed, but declared by no Plugin file."""
        pack = home_pack_dir()
        present = set(self.lockfile()) | (
            {p.name for p in pack.iterdir() if p.is_dir()} if pack.is_dir() else set()
        )
        return sorted(present - set(self.declared(plugin_files(self.config_dir))))


def home_pack_dir() -> Path:
    """Where `vim.pack` installs Plugins on the Home machine."""
    data = os.environ.get("XDG_DATA_HOME") or Path.home() / ".local" / "share"
    return Path(data) / "nvim" / "site" / "pack" / "core" / "opt"


def stage(settings: Settings, out: Path) -> list[str]:
    """Write f2dvim's `config/` and `site/` trees into `out`; return the Plugin names.

    `config/` is the config's runtime files minus the Exclusion list. `site/` is a
    packpath entry holding each packaged Plugin at its lockfile revision.
    """
    config = settings.config_dir

    def excluded(directory: str, names: list[str]) -> list[str]:
        rel = Path(directory).relative_to(config)
        return [n for n in names if rel / n in settings.exclude]

    kept = settings.kept_plugin_files()
    for entry in RUNTIME_ENTRIES:
        source = config / entry
        if source.is_dir():
            shutil.copytree(source, out / "config" / entry, ignore=excluded)
        elif source.is_file():
            (out / "config").mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, out / "config" / entry)

    lock = settings.lockfile()
    pack = home_pack_dir()
    plugins = settings.declared(kept)
    errors: list[str] = []
    for name in sorted(plugins):
        rev = lock.get(name, {}).get("rev")
        if rev is None:
            errors.append(f"{name}: not in nvim-pack-lock.json")
            continue
        if not (pack / name).is_dir():
            errors.append(f"{name}: not installed in {pack}")
            continue
        dest = out / "site" / "pack" / "f2dvim" / "opt" / name
        archive = subprocess.run(
            ["git", "-C", str(pack / name), "archive", "--format=tar", rev],
            capture_output=True,
            check=True,
        ).stdout
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            tar.extractall(dest, filter="data")
        has_license = any(_LICENSE_FILE.match(p.name) for p in dest.iterdir())
        if not has_license and name not in settings.licenses:
            errors.append(
                f"{name}: no LICENSE or COPYING file;"
                " add its SPDX id to [tool.f2dvim.licenses]",
            )
    if errors:
        raise BuildError("cannot package Plugins:\n  " + "\n  ".join(errors))

    # The stub turns vim.loader off when its cache file names (the URL-encoded path
    # of each loadable Lua file) would pass 255 bytes under the install dir. Plugin
    # tests and specs are never loaded, so they don't count.
    loadable = [*(out / "config").rglob("*.lua")] + [
        path
        for entry in RUNTIME_ENTRIES
        for path in (out / "site" / "pack" / "f2dvim" / "opt").glob(
            f"*/{entry}/**/*.lua",
        )
    ]
    longest = max(
        len(quote(str(path.relative_to(out)), safe="-_.!~*'()")) for path in loadable
    )
    (out / "longest-lua-path").write_text(f"{longest}\n")
    return sorted(plugins)


if __name__ == "__main__":
    import sys

    settings = Settings.load(Path(__file__).parent)
    commands = {
        "exclude": lambda: sorted(map(str, settings.exclude)),
        "plugins": lambda: sorted(settings.packaged_plugins()),
        "stale": settings.stale_plugins,
    }
    if len(sys.argv) != 2 or sys.argv[1] not in commands:
        sys.exit(f"usage: python bundle.py {{{','.join(commands)}}}")
    print(*commands[sys.argv[1]](), sep="\n")
