-- Jump to the start of the next / previous merge-conflict hunk. Like
-- rhysd/conflict-marker.vim, a hunk only counts when its `<<<<<<<`, `=======` and
-- `>>>>>>>` lines are all found, and from inside a hunk "previous" skips to the
-- hunk before it.
---@param forward boolean
local function jump_conflict(forward)
  local pos = vim.fn.getpos(".")
  local markers = forward and { "<<<<<<<", "=======", ">>>>>>>" }
    or { ">>>>>>>", "=======", "<<<<<<<" }
  local lines = {}
  for _, marker in ipairs(markers) do
    local lnum = vim.fn.search("^" .. marker, forward and "W" or "bW")
    if lnum == 0 then
      vim.fn.setpos(".", pos)
      return vim.notify("conflict not found", vim.log.levels.ERROR)
    end
    table.insert(lines, lnum)
  end
  vim.api.nvim_win_set_cursor(0, { forward and lines[1] or lines[3], 0 })
end

vim.keymap.set("n", "]x", function()
  jump_conflict(true)
end, { desc = "Next conflict" })
vim.keymap.set("n", "[x", function()
  jump_conflict(false)
end, { desc = "Previous conflict" })

-- Choose a side of a conflict by its markers, like diffview's `<leader>c*` maps (which
-- shadow these in its own buffers). Needs no diff, so it works in fugitive's 3-way
-- diff and in a plain buffer alike.

---Every complete conflict in `lines`, as the line numbers of its markers (`base` is
---the `|||||||` line that diff3/zdiff3 conflict styles add).
---@param lines string[]
---@return { start: integer, base?: integer, sep: integer, finish: integer }[]
local function conflicts(lines)
  local blocks, cur = {}, nil
  for i, line in ipairs(lines) do
    if line:find("^<<<<<<<") then
      cur = { start = i }
    elseif cur and not cur.sep and line:find("^|||||||") then
      cur.base = i
    elseif cur and not cur.sep and line:find("^=======") then
      cur.sep = i
    elseif cur and cur.sep and line:find("^>>>>>>>") then
      cur.finish = i
      table.insert(blocks, cur)
      cur = nil
    end
  end
  return blocks
end

---Replace the conflict under the cursor (or every one, with `all_blocks`) with its
---`side`: "ours", "theirs", "base", or "all" (ours, base and theirs, as diffview).
---@param side "ours"|"theirs"|"base"|"all"
---@param all_blocks boolean
local function choose(side, all_blocks)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local lnum = vim.fn.line(".")
  local blocks = vim.tbl_filter(function(b)
    return all_blocks or (b.start <= lnum and lnum <= b.finish)
  end, conflicts(lines))
  if #blocks == 0 then
    return vim.notify("conflict not found", vim.log.levels.ERROR)
  end
  -- Check every block first, so a missing base leaves the buffer untouched.
  if side == "base" then
    for _, b in ipairs(blocks) do
      if not b.base then
        return vim.notify(
          "conflict has no base (merge.conflictStyle zdiff3)",
          vim.log.levels.ERROR
        )
      end
    end
  end
  -- Bottom-up, so the earlier blocks' line numbers stay valid.
  for i = #blocks, 1, -1 do
    local b = blocks[i]
    local ours = vim.list_slice(lines, b.start + 1, (b.base or b.sep) - 1)
    local base = b.base and vim.list_slice(lines, b.base + 1, b.sep - 1) or {}
    local theirs = vim.list_slice(lines, b.sep + 1, b.finish - 1)
    local content = ({
      ours = ours,
      theirs = theirs,
      base = base,
      all = vim.list_extend(vim.list_extend(vim.list_slice(ours), base), theirs),
    })[side]
    vim.api.nvim_buf_set_lines(0, b.start - 1, b.finish, false, content)
  end
  local first = blocks[1].start
  vim.api.nvim_win_set_cursor(0, { math.min(first, vim.fn.line("$")), 0 })
  if all_blocks then
    vim.notify(("%d conflicts resolved (%s)"):format(#blocks, side))
  end
end

for key, side in pairs({ o = "ours", t = "theirs", b = "base", a = "all" }) do
  local name = side:gsub("^%l", function(c)
    return "[" .. c:upper() .. "]"
  end)
  vim.keymap.set("n", "<leader>c" .. key, function()
    choose(side, false)
  end, { desc = "[C]onflict: choose " .. name })
  vim.keymap.set("n", "<leader>c" .. key:upper(), function()
    choose(side, true)
  end, { desc = "[C]onflict: choose " .. name .. " (whole file)" })
end
