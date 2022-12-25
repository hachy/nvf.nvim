if vim.g.loaded_nvf == 1 then
  return
end
vim.g.loaded_nvf = 1

vim.api.nvim_create_user_command("Nvf", require("nvf").init, {})
