-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Auto select virtualenv Nvim open',
  pattern = '*',
  callback = function()
    local venv = vim.fn.findfile('pyproject.toml', vim.fn.getcwd() .. ';')
    if venv ~= '' then
      require('venv-selector').retrieve_from_cache()
    end
  end,
  once = true,
})


require "lazy_setup"
require "polish"

-- Move window borders
vim.keymap.set('n', '<C-M-h>', ':vertical resize +5<CR>', { noremap = true, silent = true }) -- Move border left
vim.keymap.set('n', '<C-M-l>', ':vertical resize -5<CR>', { noremap = true, silent = true }) -- Move border right
vim.keymap.set('n', '<C-M-j>', ':resize +5<CR>', { noremap = true, silent = true })          -- Move border down
vim.keymap.set('n', '<C-M-k>', ':resize -5<CR>', { noremap = true, silent = true })          -- Move border up

-- require('dap-go').setup()
vim.opt.clipboard = "unnamedplus"
