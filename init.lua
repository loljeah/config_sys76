-- Neovim Configuration
-- Friendly defaults for productive editing
-- Place at: ~/.config/nvim/init.lua

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------
local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs and indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

-- Clipboard - use system clipboard for all operations
-- This makes y, d, p work with system clipboard automatically
opt.clipboard = "unnamedplus"

-- Mouse support (like nano)
opt.mouse = "a"

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Undo persistence
opt.undofile = true
opt.undolevels = 10000

-- Performance
opt.updatetime = 250
opt.timeoutlen = 300

-- File handling
opt.backup = false
opt.swapfile = false
opt.fileencoding = "utf-8"

-- Show whitespace characters
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Completion
opt.completeopt = "menuone,noselect"

-- Line wrapping for markdown
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "text", "txt" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
    end
})

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader key (space)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better escape (jk or jj to exit insert mode)
keymap("i", "jk", "<Esc>", opts)
keymap("i", "jj", "<Esc>", opts)

-- Save file (Ctrl+S like nano/GUI editors)
keymap("n", "<C-s>", ":w<CR>", opts)
keymap("i", "<C-s>", "<Esc>:w<CR>a", opts)

-- Quit (Ctrl+Q)
keymap("n", "<C-q>", ":q<CR>", opts)

-- Save and quit
keymap("n", "<leader>wq", ":wq<CR>", opts)

-- Clear search highlights
keymap("n", "<Esc>", ":nohlsearch<CR>", opts)

-- Select all (Ctrl+A)
keymap("n", "<C-a>", "ggVG", opts)

-- Copy/Paste with system clipboard (already works with clipboard=unnamedplus)
-- But adding explicit mappings for clarity
keymap("v", "<C-c>", '"+y', opts)       -- Ctrl+C to copy in visual mode
keymap("n", "<C-v>", '"+p', opts)       -- Ctrl+V to paste in normal mode
keymap("i", "<C-v>", '<C-r>+', opts)    -- Ctrl+V to paste in insert mode

-- Better indenting (stay in visual mode)
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move lines up/down
keymap("n", "<A-j>", ":m .+1<CR>==", opts)
keymap("n", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)

-- Window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize windows
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Buffer navigation
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)
keymap("n", "<leader>bd", ":bdelete<CR>", opts)

-- Delete without yanking (use leader+d to delete without copying)
keymap("n", "<leader>d", '"_d', opts)
keymap("v", "<leader>d", '"_d', opts)

-- Duplicate line
keymap("n", "<leader>y", "yyp", opts)

-- Open file explorer
keymap("n", "<leader>e", ":Explore<CR>", opts)

-- Toggle line numbers
keymap("n", "<leader>n", ":set number! relativenumber!<CR>", opts)

-- Undo/Redo (Ctrl+Z, Ctrl+Y like GUI editors)
keymap("n", "<C-z>", "u", opts)
keymap("i", "<C-z>", "<C-o>u", opts)
keymap("n", "<C-y>", "<C-r>", opts)
keymap("i", "<C-y>", "<C-o><C-r>", opts)

--------------------------------------------------------------------------------
-- Auto Commands
--------------------------------------------------------------------------------
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
    group = "YankHighlight",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
})

-- Remove trailing whitespace on save
augroup("TrimWhitespace", { clear = true })
autocmd("BufWritePre", {
    group = "TrimWhitespace",
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Return to last edit position
autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Auto-create parent directories when saving
autocmd("BufWritePre", {
    callback = function(event)
        if event.match:match("^%w%w+://") then
            return
        end
        local file = vim.loop.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
})

--------------------------------------------------------------------------------
-- Colors (Cyberpunk-ish dark theme using built-in)
--------------------------------------------------------------------------------
vim.cmd([[
    colorscheme habamax
    highlight Normal guibg=#1a0f26
    highlight CursorLine guibg=#2d1f3d
    highlight LineNr guifg=#6b2d6b
    highlight CursorLineNr guifg=#ff2de2
    highlight Visual guibg=#3d1a3d
    highlight Search guibg=#bd00ff guifg=#ffffff
    highlight IncSearch guibg=#00ffff guifg=#1a0f26
    highlight Comment guifg=#6b2d6b
    highlight StatusLine guibg=#2d1f3d guifg=#00ffff
]])

--------------------------------------------------------------------------------
-- Status Line (minimal)
--------------------------------------------------------------------------------
opt.laststatus = 2
opt.statusline = " %f %m%r%h%w %= %y  %l:%c  %p%% "
