local buffer = require "nvf.buffer"
local window = require "nvf.window"
local cursor = require "nvf.cursor"
local utils = require "nvf.utils"

local M = {}

local sep = utils.sep
local list = {}

function M.create_buf(buf)
  vim.api.nvim_buf_set_name(buf, "Nvf")
  vim.api.nvim_buf_set_option(buf, "filetype", "nvf")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)

  vim.cmd("buffer " .. buf)
  vim.cmd "setlocal nowrap"
  vim.cmd "setlocal cursorline"
  vim.cmd "setlocal nonumber"
end

function M.redraw(buf, cur_path)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  local path = vim.fn.fnamemodify(cur_path, ":p")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { path })

  local fs, err = vim.loop.fs_scandir(path)
  if err then
    vim.api.nvim_err_writeln(err)
    return
  end
  list = {}
  local name, type = vim.loop.fs_scandir_next(fs)
  while name ~= nil do
    if type == "directory" then
      name = name .. sep
    end
    table.insert(list, name)
    name, type = vim.loop.fs_scandir_next(fs)
  end
  vim.api.nvim_buf_set_lines(buf, 1, -1, false, list)

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

function M.cd()
  local buf = vim.api.nvim_get_current_buf()
  local cur_path = buffer.get_cwd(buf)
  local parent_path = vim.fn.fnamemodify(cur_path, ":h")
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  if parent_path == sep then
    return
  end

  buffer.set_cwd(buf, parent_path)
  M.redraw(buf, parent_path)

  local parent_name = vim.fn.fnamemodify(cur_path, ":t") .. sep
  local parent_cursor_line
  for i, v in ipairs(list) do
    if v == parent_name then
      parent_cursor_line = i + 1
    end
  end
  cursor.new(buf, cur_path, cursor_pos)
  cursor.set(buf, parent_path, { parent_cursor_line, 0 })
end

function M.open()
  if vim.fn.line "." == 1 then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local cur_path = buffer.get_cwd(buf)
  local name = vim.api.nvim_get_current_line()
  local next_path = utils.remove_trailing_slash(vim.fs.normalize(cur_path .. sep .. name))
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  if vim.fn.isdirectory(next_path) == 1 then
    buffer.set_cwd(buf, next_path)
    M.redraw(buf, next_path)
  else
    vim.cmd("edit " .. next_path)
  end

  cursor.new(buf, cur_path, cursor_pos)
  cursor.set(buf, next_path, { 2, 0 })
end

function M.quit()
  local win = vim.api.nvim_get_current_win()
  vim.cmd("buffer " .. window.get_prev_buf(win))
end

return M
