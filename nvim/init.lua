lorenzo@ubuntu-4gb-hel1-4 ~/.c/c/net.d> ls
cni.lock
lorenzo@ubuntu-4gb-hel1-4 ~/.c/c/net.d> cd ..
lorenzo@ubuntu-4gb-hel1-4 ~/.c/cni> ls -la
total 12
drwx------ 3 lorenzo lorenzo 4096 Feb 12 19:15 ./
drwx------ 8 lorenzo lorenzo 4096 Feb 13 17:48 ../
drwx------ 2 lorenzo lorenzo 4096 Feb 12 19:15 net.d/
lorenzo@ubuntu-4gb-hel1-4 ~/.c/cni> cd ..
lorenzo@ubuntu-4gb-hel1-4 ~/.config> cd nvim
lorenzo@ubuntu-4gb-hel1-4 ~/.c/nvim> ls
init.lua  lazy-lock.json  lua/
lorenzo@ubuntu-4gb-hel1-4 ~/.c/nvim> cat init.lua
-- 1. Instalador automático de Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Definición de Plugins
require("lazy").setup({
  -- El tema Ayu
  { "Shatur/neovim-ayu" },

  -- Treesitter para resaltado
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate"
  },
})

-- 3. Configuración de Treesitter (con seguridad pcall)
local status_ts, ts = pcall(require, "nvim-treesitter.configs")
if status_ts then
  ts.setup({
    ensure_installed = { "toml", "lua", "vim", "bash" },
    highlight = { enable = true },
  })
end

-- 4. Configuración de Ayu y Estética
vim.opt.termguicolors = true
vim.opt.number = true

-- Puedes elegir entre 'ayu-light', 'ayu-mirage' o 'ayu-dark'
local status_ayu, _ = pcall(vim.cmd.colorscheme, "ayu-dark")
if not status_ayu then
    -- Si falla porque aún no se descargó, ponemos uno por defecto para que no explote
    vim.cmd.colorscheme("habamax")
end

-- 5. DETECCIÓN DE QUADLETS
vim.filetype.add({
  extension = {
    container = "toml",
    volume    = "toml",
    network   = "toml",
    kube      = "toml",
    image     = "toml",
    pod       = "toml",
  },
})
