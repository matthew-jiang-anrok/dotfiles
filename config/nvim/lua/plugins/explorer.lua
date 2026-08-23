return {
  -- Remove neo-tree; use snacks explorer instead
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  -- Open the snacks explorer in a floating window
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            layout = { preset = "default", preview = true },
          },
        },
      },
    },
  },
}
