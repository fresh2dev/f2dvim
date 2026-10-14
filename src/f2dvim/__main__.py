"""The `f2dvim` command: run the real `nvim` against the config inside this package."""

import json
import os
import shutil
import sys
from pathlib import Path
from typing import NoReturn

APP_NAME = "f2dvim"
PACKAGE_DIR = Path(__file__).parent


def nvim_argv(nvim: str, args: list[str]) -> list[str]:
    """The `nvim` command line that loads the packaged config, stub first.

    Args:
        nvim: Path to the `nvim` executable.
        args: Arguments passed through to `nvim`.

    Returns:
        The full argv, starting with `nvim`.
    """
    stub = json.dumps(str(PACKAGE_DIR / "stub.lua"), ensure_ascii=False)
    return [
        nvim,
        "--cmd",
        f"lua dofile({stub})",
        "-u",
        str(PACKAGE_DIR / "config" / "init.lua"),
        *args,
    ]


def main() -> NoReturn:
    nvim = shutil.which("nvim")
    if nvim is None:
        sys.exit(f"{APP_NAME}: nvim not found on PATH")
    # Keeps Neovim's state, data and cache apart from a stock nvim's.
    os.environ["NVIM_APPNAME"] = APP_NAME
    os.execv(nvim, nvim_argv(nvim, sys.argv[1:]))


if __name__ == "__main__":
    main()
