-- leader key is set in init.lua before lazy loads
local keymap = vim.keymap

---------------------
-- General Keymaps
---------------------

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>")

-- clear search highlights
keymap.set("n", "<leader>h", ":nohl<cr>")

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>")
keymap.set("n", "<leader>-", "<C-x>")

-- window management
keymap.set("n", "<leader>sv", "<C-w>v")
keymap.set("n", "<leader>sh", "<C-w>s")
keymap.set("n", "<leader>se", "<C-w>=")
keymap.set("n", "<leader>sx", ":close<cr>")

-- tab management
keymap.set("n", "<leader>to", ":tabnew<cr>")
keymap.set("n", "<leader>tx", ":tabclose<cr>")
keymap.set("n", "<S-l>", ":tabn<cr>")
keymap.set("n", "<S-h>", ":tabp<cr>")

-- save, kill
keymap.set("n", "<leader>w", ":w<cr>")
keymap.set("n", "<leader>q", ":q<cr>")
keymap.set("n", "<leader>x", ":xa<cr>")
keymap.set("n", "<leader>bd", ":bd<cr>")

----------------------
-- Plugin Keybinds
----------------------

-- vim-maximizer
keymap.set("n", "<leader>sm", ":MaximizerToggle<cr>")

-- nvim-tree
keymap.set("n", "<leader>e", ":NvimTreeToggle<cr>")

-- telescope
keymap.set("n", "<leader>f", "<cmd>Telescope find_files<cr>")
keymap.set("n", "<leader>ft", "<cmd>Telescope live_grep<cr>")
keymap.set("n", "<leader>bf", "<cmd>Telescope buffers<cr>")
keymap.set("n", "<leader>sh", "<cmd>Telescope help_tags<cr>")
keymap.set("n", "<leader>tf", "<cmd>TodoTelescope<cr>")

-- harpoon keymaps are set in the harpoon plugin spec (lua/brad/plugins.lua)
-- <leader>a  → add file
-- <leader>mf → toggle menu
-- <C-1/2/3/4> → jump to file 1-4

-- terminal
keymap.set("n", "<leader>tt", function()
  vim.cmd("botright split")
  vim.cmd("resize 15")
  vim.cmd("terminal")
  vim.cmd("startinsert")
end, { desc = "Open terminal at bottom" })

-- vim-tmux-navigator: terminal mode support
-- Without these, <C-h/j/k/l> go to the shell process instead of vim-tmux-navigator
keymap.set("t", "<C-h>", "<C-\\><C-N>:TmuxNavigateLeft<CR>")
keymap.set("t", "<C-j>", "<C-\\><C-N>:TmuxNavigateDown<CR>")
keymap.set("t", "<C-k>", "<C-\\><C-N>:TmuxNavigateUp<CR>")
keymap.set("t", "<C-l>", "<C-\\><C-N>:TmuxNavigateRight<CR>")
