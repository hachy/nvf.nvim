local buffer = require "nvf.buffer"
local view = require "nvf.view"
local utils = require "nvf.utils"

local M = {}
local sep = utils.sep
local clipboard
local paste_path

local function full_path(line, input)
  if line == 1 then
    local buf = vim.api.nvim_get_current_buf()
    local cur_path = buffer.get_cwd(buf)
    return vim.fs.normalize(cur_path .. sep .. input)
  end
  local cur_line_path = view.get_absolute_path(line)
  local parent_path
  local path
  if view.is_expanded(line) then
    parent_path = vim.fn.fnamemodify(cur_line_path, ":p")
    path = parent_path .. input
  else
    parent_path = vim.fn.fnamemodify(cur_line_path, ":h")
    path = parent_path .. sep .. input
  end
  return vim.fs.normalize(path)
end

local function msg_already_exists(path)
  vim.cmd "redraw"
  vim.api.nvim_echo({ { string.format("%s already exists", path), "WarningMsg" } }, true, {})
end

local function cursor_after_action(input)
  if type(input) == "string" then
    for i, v in ipairs(view.get_list()) do
      if v.name == input then
        return vim.api.nvim_win_set_cursor(0, { i + 1, 0 })
      end
    end
    return vim.api.nvim_win_set_cursor(0, { 1, 0 })
  else
    vim.api.nvim_win_set_cursor(0, { input, 0 })
  end
end

local function redraw(input)
  local buf = vim.api.nvim_get_current_buf()
  view.redraw(buf, buffer.get_cwd(buf))
  cursor_after_action(input)
end

function M.create_file()
  vim.ui.input({ prompt = "New file: ", completion = "file" }, function(input)
    if not input then
      return
    end

    local path = full_path(vim.fn.line ".", input)

    if vim.loop.fs_stat(path) then
      msg_already_exists(path)
      return
    end

    local fd, err = vim.loop.fs_open(path, "w", 420)
    if not fd then
      vim.cmd "redraw"
      vim.api.nvim_echo({ { err .. path, "ErrorMsg" } }, true, {})
      return
    end
    vim.loop.fs_close(fd)

    redraw(input)
  end)
end

function M.create_directory()
  vim.ui.input({ prompt = "New directory: ", completion = "file" }, function(input)
    if not input then
      return
    end

    local path = full_path(vim.fn.line ".", input)

    if vim.loop.fs_stat(path) then
      msg_already_exists(path)
      return
    end

    vim.fn.mkdir(path, "p")
    redraw(input .. sep)
  end)
end

function M.rename()
  local line = vim.fn.line "."
  if line == 1 then
    return
  end
  local path = view.get_absolute_path(line)
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
      vim.api.nvim_echo({ { err .. path, "ErrorMsg" } }, true, {})
      return
    end

    redraw(line)
  end)
end

function M.delete()
  local line = vim.fn.line "."
  if line == 1 then
    return
  end
  local path = view.get_absolute_path(line)

  if vim.fn.confirm("Delete?: " .. path, "&Yes\n&No", 1) ~= 1 then
    return
  end

  if vim.fn.delete(path, "rf") ~= 0 then
    vim.cmd "redraw"
    vim.api.nvim_echo({ { "Couldn't delete " .. path, "ErrorMsg" } }, true, {})
  end

  local bl = vim.fn.getbufinfo { buflisted = 1 }
  for _, v in pairs(bl) do
    if v.name == path then
      vim.cmd.bwipeout(v.bufnr)
    end
  end

  redraw(line - 1)
end

function M.copy()
  local line = vim.fn.line "."
  if line == 1 then
    return
  end
  local path = view.get_absolute_path(line)
  clipboard = utils.remove_trailing_slash(path)
  vim.api.nvim_echo({ { "Copied " .. clipboard, "DiagnosticInfo" } }, true, {})
end

local function copy_recursively(from_path, to_path)
  local from = utils.remove_trailing_slash(from_path)
  local to = utils.remove_trailing_slash(to_path)
  local stat = assert(vim.loop.fs_stat(from))

  if vim.loop.fs_stat(to) then
    msg_already_exists(to)
    if vim.fn.confirm("Rename?", "&Yes\n&Cancel") == 1 then
      vim.ui.input({ prompt = "Rename to: ", default = to, completion = "file" }, function(renamed_path)
        paste_path = renamed_path
        copy_recursively(from, renamed_path)
      end)
      return
    else
      return
    end
  end

  local fs, err = vim.loop.fs_scandir(from)
  if not fs then
    vim.api.nvim_echo({ { err, "ErrorMsg" } }, true, {})
    return
  end

  local ok, err_mkdir = vim.loop.fs_mkdir(to, stat.mode)
  if not ok then
    vim.api.nvim_echo({ { err_mkdir .. to, "ErrorMsg" } }, true, {})
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
        vim.api.nvim_echo({ { err_cp, "ErrorMsg" } }, true, {})
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
        paste_path = renamed_path
        paste_file(renamed_path)
      end)
      return
    else
      return
    end
  end

  local ok, err = vim.loop.fs_copyfile(clipboard, path)
  if not ok then
    vim.api.nvim_echo({ { err, "ErrorMsg" } }, true, {})
    return
  end
end

local function new_paste_name(path)
  local name = vim.fn.fnamemodify(path, ":t")
  if vim.fn.isdirectory(path) == 1 then
    return name .. sep
  end
  return name
end

function M.paste()
  if clipboard == nil then
    vim.api.nvim_echo({ { "The clipboard is empty", "DiagnosticInfo" } }, true, {})
    return
  end
  local path = full_path(vim.fn.line ".", vim.fs.basename(clipboard))
  paste_path = path

  if vim.fn.isdirectory(clipboard) == 1 then
    copy_recursively(clipboard, path)
  else
    paste_file(path)
  end

  local name = new_paste_name(paste_path)
  redraw(name)
end

return M
