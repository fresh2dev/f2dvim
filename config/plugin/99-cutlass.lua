-- Named after the cutlass.nvim it replaces; no plugin is installed.
-- Deletes with `x`/`X` and changes with `c`/`C` go to the blackhole register, so
-- they never clobber a yank. `d` leaves the register alone when it removes only
-- blank text (empty lines, spaces); anything else is cut as usual.
for _, mode in ipairs({ "n", "x" }) do
  for _, lhs in ipairs({ "x", "X", "c", "C" }) do
    vim.keymap.set(
      mode,
      lhs,
      '"_' .. lhs,
      { desc = lhs .. " into the blackhole register" }
    )
  end
end

local function is_blank(lines)
  return vim.iter(lines):all(function(line)
    return line:match("^%s*$") ~= nil
  end)
end

-- `d` stays Neovim's own, so `do`/`dp` and `.` keep working. The text is unknown
-- until the motion is read, so the target register is saved as the delete starts
-- and put back if what was deleted is blank. The numbered and small-delete
-- registers still record it.
local saved -- { reg, contents, type } for the delete in progress

local function save()
  local reg = vim.v.register:lower() -- `"A` appends to `a`; restore `a` itself
  saved = { reg, vim.fn.getreg(reg, 1, true), vim.fn.getregtype(reg) }
end

local group = vim.api.nvim_create_augroup("cutlass", { clear = true })
-- Fires for `.` too, which replays `d{motion}` without any mapping.
vim.api.nvim_create_autocmd("ModeChanged", {
  desc = "Save the register a delete is about to overwrite",
  group = group,
  pattern = "*:no*",
  callback = function()
    if vim.v.operator == "d" then
      save()
    end
  end,
})
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Restore the register after deleting only blank text",
  group = group,
  callback = function()
    local s = saved
    saved = nil
    if s and vim.v.event.operator == "d" and is_blank(vim.v.event.regcontents) then
      vim.fn.setreg(s[1], s[2], s[3])
    end
  end,
})
-- Back in Normal mode means the delete is done or was cancelled (`d<Esc>`), so a
-- later `:delete` never restores an old value. Deferred, as it can precede TextYankPost.
vim.api.nvim_create_autocmd("ModeChanged", {
  desc = "Forget the saved register once the delete is over",
  group = group,
  pattern = "*:n*",
  callback = function()
    vim.schedule(function()
      saved = nil
    end)
  end,
})

-- Native `D` and visual `d` never enter Operator-pending mode. `D` becomes `d$`,
-- which does (so `.` after it is covered too); visual `d` saves the register itself.
vim.keymap.set(
  "n",
  "D",
  "d$",
  { desc = "Delete to end of line (blank: keep register)" }
)
vim.keymap.set("x", "d", function()
  save()
  return "d"
end, { expr = true, desc = "Delete (blank: keep register)" })

-- Typing over a Select-mode selection (snippet placeholders) does the same.
for code = 33, 126 do
  local char = vim.fn.nr2char(code)
  vim.keymap.set(
    "s",
    char,
    '<C-o>"_c' .. char,
    { desc = "Replace selection, old text into the blackhole register" }
  )
end
vim.keymap.set(
  "s",
  "<Space>",
  '<C-o>"_c<Space>',
  { desc = "Replace selection, old text into the blackhole register" }
)
vim.keymap.set(
  "s",
  "<BS>",
  '<C-o>"_c',
  { desc = "Delete selection into the blackhole register" }
)
