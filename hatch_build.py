"""Hatchling build hook: stage the Neovim config and its Plugins into the wheel."""

import sys
import tempfile
from pathlib import Path
from typing import Any

from hatchling.builders.hooks.plugin.interface import BuildHookInterface

sys.path.insert(0, str(Path(__file__).parent))
import bundle


class F2dvimBuildHook(BuildHookInterface):
    def initialize(self, version: str, build_data: dict[str, Any]) -> None:
        # Editable installs (`uv run`) only need the Python code.
        if self.target_name != "wheel" or version == "editable":
            return
        self._stage = tempfile.TemporaryDirectory(prefix="f2dvim-")
        out = Path(self._stage.name)
        plugins = bundle.stage(bundle.Settings.load(Path(self.root)), out)
        self.app.display_info(f"f2dvim: packaged {len(plugins)} Plugins")
        for entry in ("config", "site", "longest-lua-path"):
            build_data["force_include"][str(out / entry)] = f"f2dvim/{entry}"

    def finalize(self, version: str, build_data: dict[str, Any], artifact: str) -> None:
        if stage := getattr(self, "_stage", None):
            stage.cleanup()
