from pathlib import Path

import pytest
from bundle import home_pack_dir


@pytest.mark.parametrize(
    ("appname", "expected"),
    [(None, "nvim"), ("f2dvim", "nvim"), ("custom", "custom")],
)
def test_follows_nvim_appname_except_f2dvims_own(
    monkeypatch: pytest.MonkeyPatch,
    appname: str | None,
    expected: str,
) -> None:
    monkeypatch.setenv("XDG_DATA_HOME", "/data")
    if appname is None:
        monkeypatch.delenv("NVIM_APPNAME", raising=False)
    else:
        monkeypatch.setenv("NVIM_APPNAME", appname)
    assert home_pack_dir() == Path("/data", expected, "site", "pack", "core", "opt")
