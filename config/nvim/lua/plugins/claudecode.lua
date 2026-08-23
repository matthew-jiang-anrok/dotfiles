return {
  "coder/claudecode.nvim",
  opts = {
    diff_opts = { layout = "unified" }, -- inline diff instead of side-by-side split
    terminal = {
      provider = "snacks",
      split_side = "right",
      split_width_percentage = 0.30,
    },
  },
}
