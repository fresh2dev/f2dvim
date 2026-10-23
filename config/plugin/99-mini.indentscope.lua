vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.indentscope" },
})

local MiniIndentscope = require("mini.indentscope")

MiniIndentscope.setup({
  draw = {
    -- Delay (in ms) between event and start of drawing scope indicator
    delay = 100,
    animation = MiniIndentscope.gen_animation.none(),
    priority = 2,
  },
  mappings = {
    -- `ii`/`ai` mimic michaeljsmith/vim-indent-object (not installed).
    object_scope = "ii",
    object_scope_with_border = "ai",
    -- Motions (jump to respective border line; if not present - body line)
    -- goto_top = '[i',
    -- goto_bottom = ']i',
    goto_top = "g<",
    goto_bottom = "g>",
  },
  options = {
    -- Type of scope's border: which line(s) with smaller indent to
    -- categorize as border. Can be one of: 'both', 'top', 'bottom', 'none'.
    -- border = 'both',
    -- Whether to use cursor column when computing reference indent.
    -- Useful to see incremental scopes with horizontal cursor movements.
    indent_at_cursor = false,
    -- Whether to first check input line to be a border of adjacent scope.
    -- Use it if you want to place cursor on function header to get scope of
    -- its body.
    try_as_border = false,
  },
  symbol = "╎",
})
