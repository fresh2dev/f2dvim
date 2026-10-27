-- TODO: temporary local checkout while the plugin is unpushed; restore this once it's
-- merged to main:
-- vim.pack.add({
--   { src = "https://github.com/fresh2dev/zellij-agent-pane" },
-- })
vim.opt.rtp:prepend(vim.fn.expand("~/projects/github.com/fresh2dev/zellij-agent-pane"))
-- rtp entries added mid-startup don't get their plugin/ sourced; the file guards reloads.
vim.cmd.runtime("plugin/zellij-agent-pane.lua")

-- A verb takes a motion (`<leader>asip`), or doubled, the current line (`<leader>ass`).
-- Visual maps must be `:` command mappings, not `<cmd>`: leaving Visual mode via `:`
-- passes the selection as the range and refreshes the `'<`/`'>` marks.
local verbs = {
  { "s", "ZapSend", "[S]end" },
  { "a", "ZapAdd", "[A]dd" },
  { "y", "ZapCopyReference", "cop[Y] the Reference to" },
  { "d", "ZapSendDiagnostics", "send the [D]iagnostics in" },
}
for _, v in ipairs(verbs) do
  local key, cmd, desc = unpack(v)
  vim.keymap.set("n", "<leader>a" .. key, "<Plug>(" .. cmd .. ")", {
    desc = "[A]gent: " .. desc .. " a motion",
  })
  vim.keymap.set("n", "<leader>a" .. key .. key, "<Plug>(" .. cmd .. "Line)", {
    desc = "[A]gent: " .. desc .. " the line",
  })
  vim.keymap.set("x", "<leader>a" .. key, ":" .. cmd .. "<CR>", {
    desc = "[A]gent: " .. desc .. " the selection",
  })
end

local maps = {
  { "i", "ZapSend", "send an [I]nstruction" },
  { "q", "ZapSendQuickFix", "send [Q]uickfix list" },
  { "sp", "ZapSendClipboard", "[S]end the clipboard ([P]aste)" },
  { "ap", "ZapAddClipboard", "[A]dd the clipboard ([P]aste)" },
  { "f", "Zap -f", "[F]ocus the Agent pane" },
  { "x", "Zap --recreate", "replace the Agent pane with a fresh one" },
}
for _, m in ipairs(maps) do
  local key, cmd, desc = unpack(m)
  vim.keymap.set("n", "<leader>a" .. key, "<cmd>" .. cmd .. "<CR>", {
    desc = "[A]gent: " .. desc,
  })
end
