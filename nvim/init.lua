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

require('legendary').setup({
  extensions = {
    lazy_nvim = true,

    which_key = {
      -- Automatically add which-key tables to legendary
      -- see WHICH_KEY.md for more details
      auto_register = false,
      -- you can put which-key.nvim tables here,
      -- or alternatively have them auto-register,
      -- see WHICH_KEY.md
      mappings = {},
      opts = {},
      -- controls whether legendary.nvim actually binds they keymaps,
      -- or if you want to let which-key.nvim handle the bindings.
      -- if not passed, true by default
      do_binding = true,
      -- controls whether to use legendary.nvim item groups
      -- matching your which-key.nvim groups; if false, all keymaps
      -- are added at toplevel instead of in a group.
      use_groups = true,
    },
  },
})

-- Move window borders
vim.keymap.set('n', '<C-M-h>', ':vertical resize +5<CR>', { noremap = true, silent = true }) -- Move border left
vim.keymap.set('n', '<C-M-l>', ':vertical resize -5<CR>', { noremap = true, silent = true }) -- Move border right
vim.keymap.set('n', '<C-M-j>', ':resize +5<CR>', { noremap = true, silent = true })          -- Move border down
vim.keymap.set('n', '<C-M-k>', ':resize -5<CR>', { noremap = true, silent = true })          -- Move border up

-- require('dap-go').setup()
