-- `gj` / `gk`: jump to the next edge of a block of text in the cursor's column.
-- A port of haya14busa/vim-edgemotion. An "island" is a non-blank character, or a
-- blank one between two non-blank characters.

local function is_blank(char)
  return char:find("^[ \t]$") ~= nil
end

---@param lnum integer
---@param vcol integer virtual column
local function island(lnum, vcol)
  local line = vim.fn.getline(lnum)
  local char =
    vim.fn.matchstr(line, ([[^.\{-}\zs\%%<%dv.\%%>%dv]]):format(vcol + 1, vcol))
  if char == "" then
    return false
  end
  if not is_blank(char) then
    return true
  end
  local around =
    vim.fn.matchstr(line, ([[^.\{-}\zs.\%%<%dv.\%%>%dv.]]):format(vcol + 1, vcol))
  local chars = vim.fn.split(around, [[\zs]])
  return #chars == 3 and not is_blank(chars[1]) and not is_blank(chars[3])
end

--- The `j` / `k` motion (as keys) to the edge, or "" if there is none.
---@param delta 1|-1
local function edge(delta)
  if vim.fn.getcurpos()[5] > 100000 then -- `$` was used
    vim.fn.winrestview({ curswant = #vim.fn.getline(".") - 1 })
  end
  local vcol, start, last = vim.fn.virtcol("."), vim.fn.line("."), vim.fn.line("$")
  local lnum = start

  if island(start, vcol) and island(start + delta, vcol) then
    -- inside a block: go to its far edge
    while lnum ~= 0 and lnum <= last and island(lnum, vcol) do
      lnum = lnum + delta
    end
    lnum = lnum - delta
  else
    -- on a block's edge or in the sea: go to the next block
    if island(start, vcol) then
      lnum = lnum + delta
    end
    while lnum ~= 0 and lnum <= last and not island(lnum, vcol) do
      lnum = lnum + delta
    end
  end

  if lnum == 0 or lnum == last + 1 then
    return ""
  end
  return math.abs(lnum - start) .. (delta > 0 and "j" or "k")
end

-- NOTE: plain `j`/`k` without a count already move by *visual* line (init.lua),
-- so the builtin `gj`/`gk` are free to be repurposed here.
vim.keymap.set({ "n", "x", "o" }, "gj", function()
  return edge(1)
end, { expr = true, desc = "Next edge below" })
vim.keymap.set({ "n", "x", "o" }, "gk", function()
  return edge(-1)
end, { expr = true, desc = "Next edge above" })
