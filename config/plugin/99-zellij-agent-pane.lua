-- TODO: temporary local checkout while the plugin is unpushed; restore this once it's
-- merged to main:
-- vim.pack.add({
--   { src = "https://github.com/fresh2dev/zellij-agent-pane" },
-- })
vim.opt.rtp:prepend(vim.fn.expand("~/projects/github.com/fresh2dev/zellij-agent-pane"))
-- rtp entries added mid-startup don't get their plugin/ sourced; the file guards reloads.
vim.cmd.runtime("plugin/zellij-agent-pane.lua")

-- Visual maps must be `:` command mappings, not `<cmd>`: leaving Visual mode via `:`
-- passes the selection as the range and refreshes the `'<`/`'>` marks.
-- Each asks for an Instruction and Submits on <Enter>; <Esc> cancels.
local maps = {
  { "n", "a", "ZapSend", "Send prompt to Agent Pane" },
  { "x", "a", "ZapSend", "Send selection to Agent Pane" },
  { "n", "q", "ZapSendQuickFix", "Send quickfix to Agent Pane" },
  { "n", "p", "ZapSendClipboard", "Send clipboard to Agent Pane" },
  { "n", "t", "Zap --toggle", "Toggle visibility of the Agent Pane" },
}
for _, m in ipairs(maps) do
  local mode, key, cmd, desc = unpack(m)
  local prefix = mode == "x" and ":" or "<cmd>"
  vim.keymap.set(mode, "<leader>a" .. key, prefix .. cmd .. "<CR>", {
    desc = "[A]gent: " .. desc,
  })
end
