local nls = require("null-ls")

local root_has_file = function(files)
  return function(utils)
    return utils.root_has_file(files)
  end
end
local eslint_root_files = { ".eslintrc", ".eslintrc.js", ".eslintrc.json" }
local prettier_root_files = { ".prettierrc", ".prettierrc.js", ".prettierrc.json" }

nls.setup {
  on_attach = require("lvim.lsp").common_on_attach,
  debounce = 150,
  save_after_format = false,
  root_dir = require("null-ls.utils").root_pattern(".git", "package.json"),
  sources = {
    require("typescript.extensions.null-ls.code-actions"),
    nls.builtins.diagnostics.eslint_d.with {
      condition = root_has_file(eslint_root_files),
      prefer_local = "node_modules/.bin",
    },
    nls.builtins.formatting.eslint_d.with {
      condition = root_has_file(eslint_root_files),
      prefer_local = "node_modules/.bin",
    },
    nls.builtins.formatting.prettierd.with {
      condition = function(utils)
        local has_eslint = root_has_file(eslint_root_files)(utils)
        local has_prettier = root_has_file(prettier_root_files)(utils)
        return not has_eslint and has_prettier
      end,
      prefer_local = "node_modules/.bin",
    },
    nls.builtins.code_actions.eslint_d.with {
      condition = root_has_file(eslint_root_files),
      prefer_local = "node_modules/.bin",
    },
  },
}
