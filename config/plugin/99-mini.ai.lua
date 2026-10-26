vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.ai" },
})

local ai = require("mini.ai")

--- `ae` / `ie`: the entire buffer. `ie` skips blank lines at the start and end.
--- Same as mini.extra's `gen_ai_spec.buffer()`.
local function entire_buffer(ai_type)
  local first, last = 1, vim.fn.line("$")
  if ai_type == "i" then
    first, last = vim.fn.nextnonblank(first), vim.fn.prevnonblank(last)
    if first == 0 or last == 0 then
      return { from = { line = 1, col = 1 } }
    end
  end
  local to_col = math.max(vim.fn.getline(last):len(), 1)
  return { from = { line = first, col = 1 }, to = { line = last, col = to_col } }
end

--- `av` / `iv`: a subword of camelCase, snake_case, kebab-case or UPPER_CASE on
--- the cursor line. `av` adds the separator after it, or before it when it is
--- the last part.
-- shortcut: only the cursor line is searched, so `iv` never jumps to the next line,
-- and on a separator it picks the next subword where nvim-various-textobjs picked
-- the previous one.
local function subword(ai_type)
  local lnum = vim.fn.line(".")
  local line = vim.fn.getline(lnum)
  local regions, covered = {}, {}
  local function add(from, to)
    for col = from, to do
      covered[col] = true
    end
    if ai_type == "a" then
      if line:sub(to + 1, to + 1):find("[_-]") then
        to = to + 1
      elseif from > 1 and line:sub(from - 1, from - 1):find("[_-]") then
        from = from - 1
      end
    end
    table.insert(
      regions,
      { from = { line = lnum, col = from }, to = { line = lnum, col = to } }
    )
  end

  for _, pattern in ipairs({ "%u[%u%d]+", "%a[%l%d]+", "%d+" }) do
    local init = 1
    while true do
      local from, to = line:find(pattern, init)
      if not from then
        break
      end
      init = to + 1
      -- "HTTPServer": the last capital starts the next subword
      if pattern == "%u[%u%d]+" and line:sub(to + 1, to + 1):find("%l") then
        to = to - 1
      end
      add(from, to)
    end
  end
  -- A single letter ("x" in "xSide") only where nothing else covers it.
  for col in line:gmatch("()%a") do
    if not covered[col] then
      add(col, col)
    end
  end
  return regions
end

ai.setup({
  custom_textobjects = {
    e = entire_buffer,
    v = subword,
    -- `aF`/`iF`: around/inside a function definition (not a call), via treesitter
    F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
  },

  -- Number of lines within which textobject is searched
  n_lines = 500,

  -- Module mappings. Use `''` (empty string) to disable one.
  mappings = {
    around = "a",
    inside = "i",
    around_next = "", -- 'an',
    inside_next = "", -- 'in',
    around_last = "", -- 'al',
    inside_last = "", -- 'il',
    -- Move cursor to corresponding edge of `a` textobject
    goto_left = "g[",
    goto_right = "g]",
  },
})
