local config = require "nvf.config"
local buffer = require "nvf.buffer"
local window = require "nvf.window"
local cursor = require "nvf.cursor"
local utils = require "nvf.utils"
local highlight = require "nvf.highlight"

local M = {}

local sep = utils.sep
local list = {}

local function new_buffer(buf)
  vim.api.nvim_buf_set_option(buf, "filetype", "nvf")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)

  vim.cmd("buffer " .. buf)
  vim.opt_local.wrap = false
  vim.opt_local.cursorline = true
  vim.opt_local.number = false
end

function M.create_default_buf(buf)
  vim.api.nvim_buf_set_name(buf, "[nvf]-default")
  new_buffer(buf)
end

function M.create_new_buf(buf)
  vim.api.nvim_buf_set_name(buf, "[nvf]-" .. buf)
  new_buffer(buf)
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
    local link = nil
    if type == "directory" then
      name = name .. sep
    elseif type == "link" then
      local fs_stat = vim.loop.fs_stat(path .. name)
      if fs_stat.type == "directory" then
        name = name .. sep
      end
      type = fs_stat.type
      link = type
    end
    if not config.default.show_hidden_files then
      if not vim.startswith(name, ".") then
        table.insert(list, { name = name, type = type, link = link })
      end
    else
      table.insert(list, { name = name, type = type, link = link })
    end
    name, type = vim.loop.fs_scandir_next(fs)
  end

  table.sort(list, sort)

  local names = vim.tbl_map(function(t)
    return t.name
  end, list)

  vim.api.nvim_buf_set_lines(buf, 1, -1, false, names)

  highlight.render(list)

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

function M.up()
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

local function cd_to(next_path)
  local buf = vim.api.nvim_get_current_buf()
  local cur_path = buffer.get_cwd(buf)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  buffer.set_cwd(buf, next_path)
  M.redraw(buf, next_path)

  cursor.new(buf, cur_path, cursor_pos)
  cursor.set(buf, next_path, { 2, 0 })
end

function M.cwd()
  cd_to(vim.loop.cwd())
end

function M.home()
  cd_to(vim.loop.os_homedir())
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
