"""Smoke test: run f2dvim from the built wheel, as an installed user would."""

import json
import os
import re
import shutil
import subprocess
import tempfile
from collections.abc import Iterator
from pathlib import Path

import pytest

import bundle

PROJECT_DIR = Path(__file__).parents[1]


@pytest.fixture(scope="session")
def wheel(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """A fresh build of the wheel, on a machine that can build and run it."""
    if shutil.which("nvim") is None:
        pytest.skip("nvim is not on PATH")
    # Only the Home machine has the Plugins the build packages (not CI).
    if not bundle.home_pack_dir().is_dir():
        pytest.skip(f"no Plugins installed in {bundle.home_pack_dir()}")
    out = tmp_path_factory.mktemp("dist")
    subprocess.run(
        ["uv", "build", "--wheel", "-q", "-o", out],
        cwd=PROJECT_DIR,
        check=True,
    )
    return next(out.glob("*.whl"))


@pytest.fixture
def xdg_root() -> Iterator[Path]:
    """XDG dirs at a realistic depth: /tmp/f2dvim-xxxx, like ~/.cache."""
    root = Path(tempfile.mkdtemp(prefix="f2dvim-", dir="/tmp"))
    yield root
    shutil.rmtree(root)


def test_runs_from_the_wheel_without_cloning(
    wheel: Path,
    tmp_path: Path,
    xdg_root: Path,
) -> None:
    # A `git` on PATH that records and refuses any clone.
    clones = tmp_path / "clones"
    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()
    git = fake_bin / "git"
    git.write_text(
        "#!/bin/sh\n"
        f'for a; do [ "$a" = clone ] && {{ echo "$*" >> "{clones}"; exit 1; }}; done\n'
        f'exec "{shutil.which("git")}" "$@"\n',
    )
    git.chmod(0o755)
    # uv unpacks the wheel under pytest's deep temp dir, deeper than even
    # `uvx --no-cache`, so the stub must turn vim.loader off for cache names to fit.
    env = {
        **os.environ,
        "UV_CACHE_DIR": str(tmp_path / "uv-cache"),
        "PATH": f"{fake_bin}{os.pathsep}{os.environ['PATH']}",
        **{
            f"XDG_{d.upper()}_HOME": str(xdg_root / d)
            for d in ("config", "data", "state", "cache")
        },
    }

    files = {
        "init.lua": 'print("hi")\n',
        "notes.md": "# Notes\n\n- item\n",
        "app.py": "x = 1\n",
    }
    for name, text in files.items():
        (tmp_path / name).write_text(text)
    messages = tmp_path / "messages"
    dump = f"lua vim.fn.writefile(vim.split(vim.fn.execute('messages'), '\\n'), {json.dumps(str(messages))})"
    edits = [arg for name in files for arg in ("-c", f"edit {tmp_path / name}")]

    result = subprocess.run(
        [
            "uvx",
            "--from",
            wheel,
            "f2dvim",
            "--headless",
            *edits,
            "-c",
            dump,
            "-c",
            "qall!",
        ],
        env=env,
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )

    output = result.stdout + result.stderr + messages.read_text()
    assert result.returncode == 0, output
    assert not re.search(r"\bE\d+:|Error", output), output
    assert not clones.exists(), clones.read_text()
    assert (xdg_root / "data" / "f2dvim").is_dir()
