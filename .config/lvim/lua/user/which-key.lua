local wk = lvim.builtin.which_key

wk.mappings["a"] = { ":Alpha<CR>", "Dashboard" }

wk.mappings["S"] = {
  name = "Persistence",
  s = { "<cmd>lua require('persistence').load()<CR>", "Reload last session for dir" },
  l = { "<cmd>lua require('persistence').load({ last = true })<CR>", "Restore last session" },
  Q = { "<cmd>lua require('persistence').stop()<CR>", "Quit without saving session" },
}

wk.mappings["x"] = { ":xa<CR>", "Save All and Quit", }

wk.mappings["l"]["R"] = { ":LspRestart<CR>", "Restart" }

wk.mappings["t"] = {
  name = ' Telescope',
  p = { ':Telescope projects<CR>', 'Projects' }, -- requires telescope-project.nvim plugin
  r = { ':Telescope resume<CR>', 'Resume' },
}
