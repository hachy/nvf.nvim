local buffer = require "nvf.buffer"
local utils = require "nvf.utils"

local M = {}

local function full_path(input)
  local buf = vim.api.nvim_get_current_buf()
  local cur_path = buffer.get_cwd(buf)
  return vim.fs.normalize(cur_path .. utils.sep .. input)
end

local function msg_already_exists(path)
  vim.cmd "redraw"
  vim.api.nvim_notify(string.format("%s already exists", path), vim.log.levels.WARN, {})
end

local function redraw()
  local buf = vim.api.nvim_get_current_buf()
  require("nvf.view").redraw(buf, buffer.get_cwd(buf))
end

function M.create_file()
  vim.ui.input({ prompt = "New file: ", completion = "file" }, function(input)
    if not input then
      return
    end

    local path = full_path(input)

    if vim.loop.fs_stat(path) then
      msg_already_exists(path)
      return
    end

    local fd, err = vim.loop.fs_open(path, "w", 420)
    if not fd then
      vim.cmd "redraw"
      vim.api.nvim_notify(err .. path, vim.log.levels.ERROR, {})
      return
    end
    vim.loop.fs_close(fd)

    redraw()
  end)
end

function M.create_directory()
  vim.ui.input({ prompt = "New directory: ", completion = "file" }, function(input)
    if not input then
      return
    end

    local path = full_path(input)

    if vim.loop.fs_stat(path) then
      msg_already_exists(path)
      return
    end

    vim.fn.mkdir(path, "p")
    redraw()
  end)
end

function M.rename()
  if vim.fn.line "." == 1 then
    return
  end
  local name = vim.api.nvim_get_current_line()
  local path = utils.remove_trailing_slash(full_path(name))
  vim.ui.input({ prompt = "Rename to: ", default = path, completion = "file" }, function(new_path)
    if not new_path then
      return
    end

    new_path = utils.remove_trailing_slash(new_path)

    if vim.loop.fs_stat(new_path) then
      msg_already_exists(new_path)
      return
    end

    local ok, err = vim.loop.fs_rename(path, new_path)
    if not ok then
      vim.cmd "redraw"
      vim.api.nvim_notify(err .. path, vim.log.levels.ERROR, {})
      return
    end

    redraw()
  end)
end

function M.delete()
  if vim.fn.line "." == 1 then
    return
  end
  local name = vim.api.nvim_get_current_line()
  local path = full_path(name)

  if vim.fn.confirm("Delete?: " .. path, "&Yes\n&No", 1) ~= 1 then
    return
  end

  if vim.fn.delete(path, "rf") ~= 0 then
    vim.cmd "redraw"
    vim.api.nvim_notify("Couldn't delete " .. path, vim.log.levels.ERROR, {})
  end

  redraw()
end

return M
