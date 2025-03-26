---@diagnostic disable: missing-fields
return {
  -- Enhance motion/search with tags
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {
      modes = {
        -- Enable search  mode
        search = { enabled = true },
        char = {
          -- Just use vanilla motions to repeat f/F/t/T
          char_actions = function(_)
            return {
              [';'] = 'next', -- set to `right` to always go right
              [','] = 'prev', -- set to `left` to always go left
            }
          end,
          -- Just highlight search char and not dim background for minimal UI
          highlight = {
            backdrop = false,
            groups = {
              match = 'FlashMatch',
              label = 'FlashCharLabel',
            },
          },
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "/", mode = { "v" }, function() require("flash").treesitter() end, desc = "Flash Treesitter Select" },
      { "<leader>/", mode = { "n", "x", "o" }, function() require("flash").treesitter({ jump = { pos = "start", label = { before = true, after = false }}}) end, desc = "Flash Treesitter Select" },
      { "<c-/>", mode = { "n", "x", "o" }, function() require("flash").treesitter({ jump = { pos = "end", label = { before = false, after = true }}}) end, desc = "Flash Treesitter Jump" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
}
