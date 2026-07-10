-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- [[ Dependencies ]]
  "nvim-lua/plenary.nvim",
  "nvim-tree/nvim-web-devicons",

  -- [[ Colorscheme ]]
  -- Ghostty/tmux와 Catppuccin으로 통일. flavour = "auto"로 vim.o.background를 따름
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "auto",  -- vim.o.background = "light" → latte, "dark" → mocha
        background = { light = "latte", dark = "mocha" },
        transparent_background = true,
      })
      vim.cmd("colorscheme catppuccin")
    end,
  },

  -- macOS appearance 변경(3초 주기 폴링)을 감지해 vim.o.background를 업데이트
  -- catppuccin flavour = "auto"가 이 값을 읽어 테마를 자동 전환함
  {
    "f-person/auto-dark-mode.nvim",
    priority = 1001,
    config = function()
      require("auto-dark-mode").setup({
        update_interval = 3000,
        set_dark_mode = function()
          vim.o.background = "dark"
        end,
        set_light_mode = function()
          vim.o.background = "light"
        end,
      })
    end,
  },

  -- [[ Navigation ]]
  "christoomey/vim-tmux-navigator",
  "szw/vim-maximizer",

  -- [[ Editing ]]
  -- nvim-surround: Lua rewrite of vim-surround with more features
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  -- Replace with register contents (gr + motion)
  "inkarkat/vim-ReplaceWithRegister",

  -- [[ File Explorer ]]
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.cmd([[ highlight NvimTreeIndentMarker guifg=#3FC5FF ]])
      require("nvim-tree").setup({
        renderer = {
          icons = {
            glyphs = {
              folder = {
                arrow_closed = "",
                arrow_open = "",
              },
            },
          },
        },
        actions = {
          open_file = {
            window_picker = { enable = false },
          },
        },
      })
    end,
  },

  -- [[ Statusline ]]
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({ options = { theme = "catppuccin" } })
    end,
  },

  -- [[ Telescope ]]
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local themes = require("telescope.themes")
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<c-d>"] = "delete_buffer",
            },
          },
        },
        extensions = {
          ["ui-select"] = { themes.get_dropdown({}) },
        },
      })
      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
  },

  -- [[ Autocompletion ]]
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
      -- copilot-cmp is a dependency so it loads before nvim-cmp config runs
      {
        "zbirenbaum/copilot-cmp",
        dependencies = { "zbirenbaum/copilot.lua" },
        config = function()
          require("copilot_cmp").setup()
        end,
      },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      require("luasnip/loaders/from_vscode").lazy_load()
      vim.opt.completeopt = "menu,menuone,noselect"

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
        }),
        sources = cmp.config.sources({
          { name = "copilot", group_index = 2 },
          { name = "nvim_lsp", group_index = 2 },
          { name = "luasnip", group_index = 2 },
          { name = "buffer", group_index = 2 },
          { name = "path", group_index = 2 },
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            symbol_map = { Copilot = "" },
          }),
        },
      })
    end,
  },

  -- [[ Copilot ]]
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    config = function()
      require("copilot").setup({
        -- Disable built-in virtual text/panel — using copilot-cmp instead
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },

  -- [[ LSP: Mason ]]
  {
    "williamboman/mason.nvim",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls",
          "html",
          "cssls",
          "lua_ls",
          "jsonls",
        },
        automatic_installation = true,
      })
    end,
  },

  -- Mason tool installer (formatters & linters)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettier",
          "stylua",
          "eslint_d",
        },
      })
    end,
  },

  -- [[ LSP: lspconfig ]]
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp", "williamboman/mason-lspconfig.nvim" },
    config = function()
      local cmp_nvim_lsp = require("cmp_nvim_lsp")
      local keymap = vim.keymap

      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }
        keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
        keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts) -- fixed: was calling definition()
        keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>", opts)
        keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
        keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", opts)
        keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", opts)
        keymap.set("n", "<leader>D", "<cmd>Lspsaga show_line_diagnostics<CR>", opts)
        keymap.set("n", "<leader>d", "<cmd>Lspsaga show_cursor_diagnostics<CR>", opts)
        keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)
        keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)
        keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts)
        keymap.set("n", "<leader>o", "<cmd>Lspsaga outline<CR>", opts)

        if client.name == "ts_ls" then
          keymap.set("n", "<leader>oi", function()
            vim.lsp.buf.execute_command({
              command = "_typescript.organizeImports",
              arguments = { vim.api.nvim_buf_get_name(0) },
            })
          end, opts)
          keymap.set("n", "<leader>ru", function()
            vim.lsp.buf.execute_command({
              command = "_typescript.removeUnused",
              arguments = { vim.api.nvim_buf_get_name(0) },
            })
          end, opts)
        end
      end

      local capabilities = cmp_nvim_lsp.default_capabilities()

      -- Neovim 0.10+ diagnostic signs API (replaces deprecated vim.fn.sign_define)
      vim.diagnostic.config({
        underline = true,
        virtual_text = { prefix = "●" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰠠 ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      })

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- `on_attach` in vim.lsp.config() isn't invoked by vim.lsp.enable()'s
      -- client startup path in this Neovim version, so wire buffer-local
      -- keymaps via the LspAttach autocmd instead (the documented,
      -- version-stable mechanism).
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client then
            on_attach(client, args.buf)
          end
        end,
      })

      -- lua_ls: inline config so vim globals are recognized
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              },
              maxPreload = 5000,
              preloadFileSize = 10000,
            },
          },
        },
      })

      -- ts_ls: mason bundles typescript-language-server with typescript ^7.0.2
      -- (the native/Go rewrite), which the language server can't use as its
      -- tsserver backend. Point it at a classic-API typescript install instead.
      vim.lsp.config("ts_ls", {
        init_options = {
          tsserver = {
            path = vim.fn.system("npm root -g"):gsub("%s+$", "") .. "/typescript/lib/tsserverlibrary.js",
          },
        },
      })

      local servers = {
        "ts_ls",
        "lua_ls",
        "html",
        "cssls",
        "jsonls",
      }

      for _, name in ipairs(servers) do
        vim.lsp.enable(name)
      end
    end,
  },

  -- [[ LSP: lspsaga ]]
  {
    "glepnir/lspsaga.nvim",
    event = "LspAttach",
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("lspsaga").setup({
        scroll_preview = { scroll_down = "<C-f>", scroll_up = "<C-b>" },
        definition = { keys = { edit = "<CR>" } },
        rename = { in_select = false },
        ui = { colors = { normal_bg = "#022746" } },
        lightbulb = { enable = false },
      })
    end,
  },

  -- [[ Formatting (replaces null-ls) ]]
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
          lua = { "stylua" },
        },
        format_on_save = {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        },
      })
    end,
  },

  -- [[ Linting (replaces null-ls diagnostics) ]]
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
      }
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  -- [[ Treesitter ]]
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local filetypes = {
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "html",
        "css",
        "markdown",
        "bash",
        "lua",
        "vim",
        "gitignore",
        "tmux",
        "ssh_config",
      }

      require("nvim-treesitter").setup()
      require("nvim-treesitter").install(vim.list_extend(vim.deepcopy(filetypes), { "markdown_inline" }))

      vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function()
          vim.treesitter.start()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Auto-close HTML/JSX tags
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },

  -- [[ Auto Pairs ]]
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,
        ts_config = {
          lua = { "string" },
          javascript = { "template_string" },
          java = false,
        },
      })
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- [[ Todo Comments ]]
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("todo-comments").setup({})
    end,
  },

  -- [[ Harpoon v2 (replaces bookmarks.nvim) ]]
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      local keymap = vim.keymap
      keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end, { desc = "Harpoon: add file" })
      keymap.set("n", "<leader>mf", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Harpoon: menu" })
      keymap.set("n", "<C-1>", function()
        harpoon:list():select(1)
      end, { desc = "Harpoon: file 1" })
      keymap.set("n", "<C-2>", function()
        harpoon:list():select(2)
      end, { desc = "Harpoon: file 2" })
      keymap.set("n", "<C-3>", function()
        harpoon:list():select(3)
      end, { desc = "Harpoon: file 3" })
      keymap.set("n", "<C-4>", function()
        harpoon:list():select(4)
      end, { desc = "Harpoon: file 4" })
    end,
  },

  -- [[ Git ]]
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup()
    end,
  },

  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
  },

  -- [[ Markdown rendering ]]
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = "markdown",
    opts = {
      heading = {
        icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
      },
    },
  },

  -- [[ Input Method ]]
  {
    "keaising/im-select.nvim",
    config = function()
      require("im_select").setup({
        default_im_select = "com.apple.keylayout.ABC",
        default_command = "im-select",
        set_default_events = { "VimEnter", "InsertLeave", "CmdlineLeave" },
        set_previous_events = { "InsertEnter" },
      })
    end,
  },

  -- [[ Claude Code ]]
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      terminal = { enabled = true },
    },
  },

  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal = {
        split_side = "right",
        split_width_percentage = 0.30,
        provider = "snacks",
        auto_close = true,
        snacks_win_opts = {
          wo = {
            winhighlight = "Normal:Normal,NormalFloat:Normal,FloatBorder:Normal",
          },
        },
      },
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude: toggle (right)" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: focus" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: send selection" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: reject diff" },
    },
  },

  -- [[ Obsidian ]]
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = {
        {
          name = "docs",
          path = "~/workspace/docs",
        },
      },
      new_notes_location = "current_dir",
      wiki_link_func = "use_alias_only",
      completion = { nvim_cmp = true, min_chars = 2 },
      mappings = {
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        ["<leader>oc"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true, desc = "Obsidian: toggle checkbox" },
        },
        ["<cr>"] = {
          action = function()
            return require("obsidian").util.smart_action()
          end,
          opts = { buffer = true, expr = true, desc = "Obsidian: smart action" },
        },
      },
    },
  },
}, {
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
})
