local M = {}

local ns = vim.api.nvim_create_namespace "NvfHighlight"

function M.setup()
  vim.api.nvim_set_hl(0, "NvfCWD", { default = true, link = "Function" })
  vim.api.nvim_set_hl(0, "NvfDir", { default = true, link = "Preproc" })
  vim.api.nvim_set_hl(0, "NvfFile", { default = true, link = "Normal" })
  vim.api.nvim_set_hl(0, "NvfLink", { default = true, link = "Number" })
  vim.api.nvim_set_hl(0, "NvfTime", { default = true, link = "Type" })
end

function M.render(fs_stat, mtime_start)
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(0, ns, "NvfCWD", 0, 0, -1)

  for i, v in ipairs(fs_stat) do
    local name_end = #v.name + 1
    if v.type == "directory" then
      vim.api.nvim_buf_add_highlight(0, ns, "NvfDir", i, 0, name_end)
    else
      vim.api.nvim_buf_add_highlight(0, ns, "NvfFile", i, 0, name_end)
    end
    if v.link then
      vim.api.nvim_buf_add_highlight(0, ns, "NvfLink", i, 0, name_end)
    end
    vim.api.nvim_buf_add_highlight(0, ns, "NvfTime", i, mtime_start, -1)
  end
end

return M
