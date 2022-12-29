local config = require "nvf.config"
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

local function sort(a, b)
  local t1 = a.type == "directory"
  local t2 = b.type == "directory"
  if t1 and not t2 then
    return true
  elseif not t1 and t2 then
    return false
  end
  return a.name:lower() < b.name:lower()
end

function M.redraw(buf, cur_path)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  local path = vim.fn.fnamemodify(cur_path, ":p")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { path })

  local fs, err = vim.loop.fs_scandir(path)
  if not fs then
    vim.api.nvim_notify(err, vim.log.levels.ERROR, {})
    return
  end

  -- reset list
  for i, _ in ipairs(list) do
    list[i] = nil
  end

  local name, type = vim.loop.fs_scandir_next(fs)
  while name ~= nil do
    if type == "directory" then
      name = name .. sep
    end
    if not config.default.show_hidden_files then
      if not vim.startswith(name, ".") then
        table.insert(list, { name = name, type = type })
      end
    else
      table.insert(list, { name = name, type = type })
    end
    name, type = vim.loop.fs_scandir_next(fs)
  end

  table.sort(list, sort)

  local names = vim.tbl_map(function(t)
    return t.name
  end, list)

  vim.api.nvim_buf_set_lines(buf, 1, -1, false, names)

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

local function find_cursor_line_from(file_list, name)
  local cursor_line
  for i, v in ipairs(file_list) do
    if v.name == name then
      cursor_line = i + 1
      break
    end
  end
  return cursor_line
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
  local parent_cursor_line = find_cursor_line_from(list, parent_name)
  cursor.new(buf, cur_path, cursor_pos)
  cursor.set(buf, nil, { parent_cursor_line, 0 })
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

function M.toggle_hidden_files()
  config.default.show_hidden_files = not config.default.show_hidden_files
  local name = vim.api.nvim_get_current_line()

  local buf = vim.api.nvim_get_current_buf()
  local cur_path = buffer.get_cwd(buf)
  M.redraw(buf, cur_path)

  local cursor_line = find_cursor_line_from(list, name)
  cursor.new(buf, cur_path, { cursor_line, 0 })
  cursor.set(buf, nil, { cursor_line, 0 })
end

return M
