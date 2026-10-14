-- Loaded by the f2dvim launcher (`--cmd`) before init.lua. Puts the packaged config
-- and Plugins on the runtimepath and packpath, and replaces vim.pack so Plugins load
-- from the package and nothing is ever cloned. See ADR 0001.

local root = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local config = vim.fs.joinpath(root, "config")
local opt = vim.fs.joinpath(root, "site", "pack", "f2dvim", "opt")

-- vim.loader names cache files after the URL-encoded path of each Lua file, and a
-- name over 255 bytes fails to load; deep installs (`uvx --no-cache`) would hit that.
local longest = tonumber(vim.fn.readfile(vim.fs.joinpath(root, "longest-lua-path"))[1])
if #vim.uri_encode(root .. "/", "rfc2396") + longest + 1 > 255 then
  vim.loader.enable = function() end
end

vim.opt.runtimepath:prepend(config)
vim.opt.runtimepath:append(vim.fs.joinpath(config, "after"))
vim.opt.packpath:prepend(vim.fs.joinpath(root, "site"))

local added = {} ---@type table<string, true>

---@param spec string|vim.pack.Spec
---@return string
local function name_of(spec)
  spec = type(spec) == "string" and { src = spec } or spec
  return spec.name or spec.src:gsub("/$", ""):gsub("%.git$", ""):match("[^/]+$")
end

-- Mirrors vim.pack.add's loading (`packadd!` during init, `packadd` after, `after/`
-- scripts once Neovim has entered). `version` is ignored: the packaged revision is
-- the lockfile's.
---@param specs (string|vim.pack.Spec)[]
---@param opts? vim.pack.keyset.add
function vim.pack.add(specs, opts)
  opts = opts or {}
  local load = opts.load
  if load == nil then
    load = vim.v.vim_did_init == 1
  end
  for _, spec in ipairs(specs) do
    local name = name_of(spec)
    local path = vim.fs.joinpath(opt, name)
    if not vim.uv.fs_stat(path) then
      error(("f2dvim: Plugin %q is not packaged"):format(name))
    end
    if not added[name] then
      added[name] = true
      if vim.is_callable(load) then
        load({ spec = type(spec) == "table" and spec or { src = spec }, path = path })
      else
        vim.cmd.packadd({ vim.fn.escape(name, " "), bang = not load })
        if vim.v.vim_did_enter == 1 and load then
          for _, script in
            ipairs(vim.fn.glob(path .. "/after/plugin/**/*.{vim,lua}", false, true))
          do
            vim.cmd.source(script)
          end
        end
      end
    end
  end
end

local function managed()
  vim.notify("f2dvim: Plugins are managed by the f2dvim package", vim.log.levels.WARN)
end
vim.pack.update = managed
vim.pack.del = managed
