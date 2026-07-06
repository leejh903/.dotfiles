-- Set leader BEFORE lazy loads plugins
vim.g.mapleader = ","
vim.g.maplocalleader = ","

require("brad.options")
require("brad.plugins") -- bootstraps lazy.nvim and sets up all plugins
require("brad.keymaps")
