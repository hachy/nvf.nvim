local utils = require "nvf.utils"

local M = {}

local ns = vim.api.nvim_create_namespace "NvfHighlight"

function M.setup()
  vim.api.nvim_set_hl(0, "NvfCWD", { default = true, link = "Identifier" })
  vim.api.nvim_set_hl(0, "NvfDir", { default = true, link = "Preproc" })
  vim.api.nvim_set_hl(0, "NvfFile", { default = true, link = "Normal" })
end

function M.render(names)
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(0, ns, "NvfCWD", 0, 0, -1)

  for i, v in ipairs(names) do
    if vim.endswith(v, utils.sep) then
      vim.api.nvim_buf_add_highlight(0, ns, "NvfDir", i, 0, -1)
    else
      vim.api.nvim_buf_add_highlight(0, ns, "NvfFile", i, 0, -1)
    end
  end
end

return M
