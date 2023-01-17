local buffer = require "nvf.buffer"
local utils = require "nvf.utils"

local M = {}
local sep = utils.sep
local clipboard

local function full_path(input)
  local buf = vim.api.nvim_get_current_buf()
  local cur_path = buffer.get_cwd(buf)
  return vim.fs.normalize(cur_path .. sep .. input)
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

  local bl = vim.fn.getbufinfo { buflisted = 1 }
  for _, v in pairs(bl) do
    if v.name == path then
      vim.cmd.bwipeout(v.bufnr)
    end
  end

  redraw()
end

function M.copy()
  local name = vim.api.nvim_get_current_line()
  local path = full_path(name)
  clipboard = utils.remove_trailing_slash(path)
  vim.api.nvim_notify("Copied " .. clipboard, vim.log.levels.INFO, {})
end

local function copy_recursively(from_path, to_path)
  local from = utils.remove_trailing_slash(from_path)
  local to = utils.remove_trailing_slash(to_path)
  local stat = assert(vim.loop.fs_stat(from))

  if vim.loop.fs_stat(to) then
    msg_already_exists(to)
    if vim.fn.confirm("Rename?", "&Yes\n&Cancel") == 1 then
      vim.ui.input({ prompt = "Rename to: ", default = from, completion = "file" }, function(renamed_path)
        copy_recursively(from, renamed_path)
      end)
      return
    else
      return
    end
  end

  local fs, err = vim.loop.fs_scandir(from)
  if not fs then
    vim.api.nvim_notify(err, vim.log.levels.ERROR, {})
    return
  end

  local ok, err_mkdir = vim.loop.fs_mkdir(to, stat.mode)
  if not ok then
    vim.api.nvim_notify(err_mkdir .. to, vim.log.levels.ERROR, {})
    return
  end

  local name, type = vim.loop.fs_scandir_next(fs)
  while name ~= nil do
    local old_path = vim.fs.normalize(from .. sep .. name)
    local new_path = vim.fs.normalize(to .. sep .. name)
    if type == "directory" then
      copy_recursively(old_path, new_path)
    else
      local ok_cp, err_cp = vim.loop.fs_copyfile(old_path, new_path)
      if not ok_cp then
        vim.api.nvim_notify(err_cp, vim.log.levels.ERROR, {})
        return
      end
    end
    name, type = vim.loop.fs_scandir_next(fs)
  end
end

local function paste_file(path)
  if vim.loop.fs_stat(path) then
    msg_already_exists(path)
    if vim.fn.confirm("Rename?", "&Yes\n&Cancel") == 1 then
      vim.ui.input({ prompt = "Rename to: ", default = path, completion = "file" }, function(renamed_path)
        paste_file(renamed_path)
      end)
      return
    else
      return
    end
  end

  local ok, err = vim.loop.fs_copyfile(clipboard, path)
  if not ok then
    vim.api.nvim_notify(err, vim.log.levels.ERROR, {})
    return
  end
end

function M.paste()
  if clipboard == nil then
    vim.api.nvim_notify("The clipboard is empty", vim.log.levels.INFO, {})
    return
  end
  local path = full_path(vim.fs.basename(clipboard))

  if vim.fn.isdirectory(clipboard) == 1 then
    copy_recursively(clipboard, path)
  else
    paste_file(path)
  end

  redraw()
end

return M
