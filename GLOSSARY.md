# f2dvim

A personal Neovim config, and the means of carrying it to machines that cannot reach
GitHub.

## Language

**Home machine**:
The personal arm64 MacBook where the config is authored and plugins are fetched from
GitHub.
_Avoid_: Personal machine, dev machine

**Work machine**:
An arm64 MacBook with Neovim 0.12 that can reach PyPI, npm and the Go module proxy, but
not GitHub.
_Avoid_: Target, remote machine, offline machine

## Neovim config

**Plugin**:
A third-party Neovim plugin repository, named by the last segment of its source URL.
_Avoid_: Package, dependency, module

**Plugin file**:
A file under the config's `plugin/` or `ftplugin/` directory that declares and
configures one or more Plugins; the unit that is included in or left out of a Work
machine install.
_Avoid_: Plugin spec, module, feature

**Exclusion list**:
The Plugin files deliberately left out of what the Work machine receives; everything not
on it is included.
_Avoid_: Blocklist, ignore list

**Stale Plugin**:
A Plugin that is installed or locked on the Home machine but declared by no Plugin file.
_Avoid_: Orphan, unused plugin

**f2dvim**:
The Neovim config, its included Plugins and a launcher, packaged as one read-only
distribution for Work machines and published to PyPI.
_Avoid_: Bundle, wheel, work config, fork
