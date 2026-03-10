-- import cmp-nvim-lsp plugin safely
local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
  return
end

local keymap = vim.keymap -- for conciseness

-- enable keybinds only for when lsp server available
local on_attach = function(client, bufnr)
  -- keybind options
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- set keybinds
  -- keymap.set("n", "gr", "<cmd>Lspsaga finder ref<CR>", opts) -- show definition, references
  keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references
  keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.definition()<CR>") -- go to declaration
  keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>", opts) -- see definition and make edits in window
  keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts) -- go to implementation
  keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", opts) -- see available code actions
  keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", opts) -- smart rename
  keymap.set("n", "<leader>D", "<cmd>Lspsaga show_line_diagnostics<CR>", opts) -- show  diagnostics for line
  keymap.set("n", "<leader>d", "<cmd>Lspsaga show_cursor_diagnostics<CR>", opts) -- show diagnostics for cursor
  keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts) -- jump to previous diagnostic in buffer
  keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts) -- jump to next diagnostic in buffer
  keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts) -- show documentation for what is under cursor
  keymap.set("n", "<leader>o", "<cmd>Lspsaga outline<CR>", opts) -- see outline on right hand side

  -- typescript specific keymaps (ts_ls)
  if client.name == "ts_ls" then
    keymap.set("n", "<leader>oi", function()
      vim.lsp.buf.execute_command({
        command = "_typescript.organizeImports",
        arguments = { vim.api.nvim_buf_get_name(0) },
      })
    end, opts) -- organize imports
    keymap.set("n", "<leader>ru", function()
      vim.lsp.buf.execute_command({
        command = "_typescript.removeUnused",
        arguments = { vim.api.nvim_buf_get_name(0) },
      })
    end, opts) -- remove unused variables
  end
end

-- used to enable autocompletion (assign to every lsp server config)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Change the Diagnostic symbols in the sign column (gutter)
-- (not in youtube nvim video)
local signs = { Error = " ", Warn = " ", Hint = "ﴞ ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Global config applied to all servers
vim.lsp.config("*", {
  capabilities = capabilities,
  on_attach = on_attach,
})

-- setup default servers
local defaultServers = {
  "ts_ls",
  "lua_ls",
  "html",
  "cssls",
  "tailwindcss",
  "emmet_ls",
  "gopls",
  "kotlin_language_server",
  "pyright",
  "rust_analyzer",
  "dartls",
}

for _, name in ipairs(defaultServers) do
  local has_custom_provider, custom_config = pcall(require, "plugin/providers/" .. name)
  if has_custom_provider then
    vim.lsp.config(name, custom_config)
  end
  vim.lsp.enable(name)
end
