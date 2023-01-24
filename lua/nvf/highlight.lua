local M = {}

local ns = vim.api.nvim_create_namespace "NvfHighlight"

function M.setup()
  vim.api.nvim_set_hl(0, "NvfCWD", { default = true, link = "Function" })
  vim.api.nvim_set_hl(0, "NvfIcon", { default = true, link = "Constant" })
  vim.api.nvim_set_hl(0, "NvfDir", { default = true, link = "Preproc" })
  vim.api.nvim_set_hl(0, "NvfFile", { default = true, link = "Normal" })
  vim.api.nvim_set_hl(0, "NvfLink", { default = true, link = "Number" })
  vim.api.nvim_set_hl(0, "NvfTime", { default = true, link = "Type" })
end

function M.render(fs_stat, icons, mtime_start)
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(0, ns, "NvfCWD", 0, 0, -1)

  for i, v in ipairs(fs_stat) do
    local name_start = v.depth + vim.fn.strdisplaywidth(icons[v.expanded and "expanded" or v.type])
    local name_end = name_start + vim.fn.strdisplaywidth(v.name)
    vim.api.nvim_buf_add_highlight(0, ns, "NvfIcon", i, 0, name_start)
    if v.type == "directory" then
      vim.api.nvim_buf_add_highlight(0, ns, "NvfDir", i, name_start, name_end)
    else
      vim.api.nvim_buf_add_highlight(0, ns, "NvfFile", i, name_start, name_end)
    end
    if v.link then
      vim.api.nvim_buf_add_highlight(0, ns, "NvfLink", i, name_start, name_end)
    end
    vim.api.nvim_buf_add_highlight(0, ns, "NvfTime", i, mtime_start, -1)
  end
end

return M
