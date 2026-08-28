-- ============================================
-- BOOTSTRAP LAZY.NVIM
-- ============================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================
-- OPTIONS
-- ============================================
vim.g.mapleader = " "              -- space as leader

vim.opt.number = true              -- line numbers
vim.opt.relativenumber = true      -- relative (jump with 12j, 5k)
vim.opt.signcolumn = "yes"         -- always show (no layout shift)
vim.opt.cursorline = true          -- highlight current line

vim.opt.tabstop = 4                -- tab width
vim.opt.shiftwidth = 4             -- indent width
vim.opt.expandtab = true           -- spaces, not tabs
vim.opt.smartindent = true

vim.opt.clipboard = "unnamedplus"  -- system clipboard (OSC 52 via ghostty/tmux)
vim.opt.undofile = true            -- persistent undo across sessions
vim.opt.ignorecase = true          -- search case-insensitive...
vim.opt.smartcase = true           -- ...unless you use capitals
vim.opt.scrolloff = 8              -- keep 8 lines visible above/below cursor
vim.opt.updatetime = 250           -- faster CursorHold (for LSP hover etc.)
vim.opt.splitright = true          -- vertical splits open right
vim.opt.splitbelow = true          -- horizontal splits open below
vim.opt.termguicolors = true       -- true color

vim.opt.grepprg = "rg --vimgrep --smart-case"

-- ============================================
-- KEYMAPS (before plugins, so leader is set)
-- ============================================
local map = vim.keymap.set

-- window navigation (vim-tmux-navigator handles this, but useful standalone)
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- diagnostic navigation
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- ============================================
-- PLUGINS
-- ============================================
require("lazy").setup({

  -- === THEME ===
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "medium"    -- soft, medium, or hard
      vim.g.gruvbox_material_foreground = "material"   -- material, mix, or original
      vim.g.gruvbox_material_better_performance = 1
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },

  -- === TMUX INTEGRATION ===
  { "christoomey/vim-tmux-navigator" },

  -- === FUZZY FINDER (your most-used tool) ===
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({})
      pcall(require("telescope").load_extension, "fzf")

      local builtin = require("telescope.builtin")
      map("n", "<leader>f", builtin.find_files, { desc = "Find files" })
      map("n", "<leader>g", builtin.live_grep, { desc = "Grep project" })
      map("n", "<leader>b", builtin.buffers, { desc = "Buffers" })
      map("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Search buffer" })
      map("n", "<leader>d", builtin.diagnostics, { desc = "Diagnostics" })
      map("n", "<leader>r", builtin.resume, { desc = "Resume last search" })
    end,
  },

  -- === TREESITTER ===
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "lua", "python", "typescript", "javascript", "tsx",
          "go", "rust", "json", "yaml", "toml", "markdown",
          "bash", "html", "css", "dockerfile",
        },
      })
    end,
  },

  -- === LSP ===
  {
    "mason-org/mason.nvim",
    dependencies = { "mason-org/mason-lspconfig.nvim" },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "gopls", "pyright" },
      })

      -- configure servers using nvim 0.11+ native API
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      -- enable all servers (no per-server config needed for these)
      vim.lsp.enable({ "lua_ls", "ts_ls", "gopls", "pyright" })

      -- keymaps when LSP attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bmap = function(keys, func, desc)
            map("n", keys, func, { buffer = args.buf, desc = desc })
          end
          bmap("gd", vim.lsp.buf.definition, "Go to definition")
          bmap("gr", vim.lsp.buf.references, "References")
          bmap("K", vim.lsp.buf.hover, "Hover docs")
          bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
          bmap("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        end,
      })
    end,
  },


  -- === COMPLETION ===
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- === QUALITY OF LIFE ===
  {
    "lewis6991/gitsigns.nvim",       -- git status in the gutter
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          map("n", "]h", gs.next_hunk, { buffer = bufnr, desc = "Next hunk" })
          map("n", "[h", gs.prev_hunk, { buffer = bufnr, desc = "Prev hunk" })
          map("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
        end,
      })
    end,
  },

  { "tpope/vim-sleuth" },            -- auto-detect indent style

  {
    "echasnovski/mini.pairs",        -- auto-close brackets
    config = function() require("mini.pairs").setup() end,
  },

}, {
  -- lazy.nvim options
  checker = { enabled = false },     -- don't auto-check for updates
})
