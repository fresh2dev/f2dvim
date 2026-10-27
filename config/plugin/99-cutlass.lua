-- Named after the cutlass.nvim it replaces; no plugin is installed.
-- Deletes with `x`/`X` and changes with `c`/`C` go to the blackhole register, so
-- they never clobber a yank. `d` does too when it removes only blank text (empty
-- lines, spaces); anything else is cut as usual.
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

-- Normal-mode `d` is an operator: the text is unknown until the motion is read.
-- So `d` runs `g@`, and this function then deletes the region with the register
-- chosen from its content. 'operatorfunc' needs a global (it takes no Lua function).
local delete_reg
function _G.delete_operator(type)
  local mode = ({ line = "V", char = "v", block = "\22" })[type]
  local text =
    vim.fn.getregion(vim.fn.getpos("'["), vim.fn.getpos("']"), { type = mode })
  local reg = is_blank(text) and "_" or delete_reg
  vim.cmd("normal! `[" .. mode .. '`]"' .. reg .. "d")
end

for lhs, motion in pairs({ d = "", dd = "_", D = "$" }) do
  vim.keymap.set("n", lhs, function()
    delete_reg = vim.v.register
    vim.o.operatorfunc = "v:lua.delete_operator"
    return "g@" .. motion
  end, { expr = true, desc = "Delete (blank text to the blackhole register)" })
end
vim.keymap.set("x", "d", function()
  local text = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
    type = vim.fn.mode(),
  })
  return is_blank(text) and '"_d' or "d"
end, { expr = true, desc = "Delete (blank text to the blackhole register)" })

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
