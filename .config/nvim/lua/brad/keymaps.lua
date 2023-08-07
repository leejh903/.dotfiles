-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

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
keymap.set("n", "<leader>+", "<C-a>") -- increment
keymap.set("n", "<leader>-", "<C-x>") -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v") -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s") -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=") -- make split windows equal width & height
keymap.set("n", "<leader>sx", ":close<cr>") -- close current split window

keymap.set("n", "<leader>to", ":tabnew<cr>") -- open new tab
keymap.set("n", "<leader>tx", ":tabclose<cr>") -- close current tab
keymap.set("n", "<S-l>", ":tabn<cr>") --  go to next tab
keymap.set("n", "<S-h>", ":tabp<cr>") --  go to previous tab

-- save, kill
keymap.set("n", "<leader>w", ":w<cr>")
keymap.set("n", "<leader>x", ":xa<cr>")
keymap.set("n", "<leader>bd", ":bd<cr>")

----------------------
-- Plugin Keybinds
----------------------

-- vim-maximizer
keymap.set("n", "<leader>sm", ":MaximizerToggle<cr>") -- toggle split window maximization

-- nvim-tree
keymap.set("n", "<leader>e", ":NvimTreeToggle<cr>") -- toggle file explorer

-- telescope
keymap.set("n", "<leader>f", "<cmd>Telescope find_files<cr>") -- find files within current working directory, respects .gitignore
keymap.set("n", "<leader>ft", "<cmd>Telescope live_grep<cr>") -- find string in current working directory as you type
keymap.set("n", "<leader>bf", "<cmd>Telescope buffers<cr>") -- list open buffers in current neovim instance
keymap.set("n", "<leader>sh", "<cmd>Telescope help_tags<cr>") -- list available help tags
keymap.set("n", "<leader>tf", "<cmd>TodoTelescope<cr>") -- find todo comments
-- git
keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>")
