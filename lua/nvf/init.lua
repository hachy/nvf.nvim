local config = require "nvf.config"
local buffer = require "nvf.buffer"
local window = require "nvf.window"
local cursor = require "nvf.cursor"
local view = require "nvf.view"
local file = require "nvf.file"

local M = {}

local default_buf, nvf_group

local cmd = {
  quit = view.quit,
  open = view.open,
  up = view.up,
  expand_or_collapse = view.expand_or_collapse,
  cwd = view.cwd,
  home = view.home,
  toggle_hidden_files = view.toggle_hidden_files,
  create_file = file.create_file,
  create_directory = file.create_directory,
  rename = file.rename,
  delete = file.delete,
  copy = file.copy,
  paste = file.paste,
  brand_new_buffer = "<Cmd>NvfNew<CR>",
}

local function set_mappings(mappings)
  for k, v in pairs(mappings) do
    if cmd[k] then
      k = cmd[k]
    end
    vim.keymap.set("n", v, k, { buffer = true })
  end
end

local function switch_buffer(buf, win, prev_buf)
  if prev_buf == buf then
    prev_buf = window.get_prev_buf(win)
  end
  vim.api.nvim_set_current_buf(buf)
  local cwd = buffer.get_cwd(buf)
  local cursor_pos = cursor.get(buf, cwd) or vim.api.nvim_win_get_cursor(0)
  return cwd, cursor_pos, prev_buf
end

local function set_view(buf, win, cwd, cursor_pos, prev_buf)
  buffer.new(buf, cwd, buffer.get_expanded_folders(buf) or {})
  view.redraw(buf, cwd)
  window.new(win, buf, prev_buf)
  cursor.set(buf, cwd, cursor_pos or { 2, 0 })

  set_mappings(config.default.mappings)

  vim.api.nvim_create_autocmd("WinNew", {
    group = nvf_group,
    buffer = buf,
    callback = function()
      local new_win = vim.api.nvim_get_current_win()
      window.new(new_win, buf, prev_buf)
    end,
  })
end

function M.init()
  local win = vim.api.nvim_get_current_win()
  local buf_existed = window.find_buf_in(win)
  local prev_buf = vim.api.nvim_get_current_buf()
  local cwd
  local cursor_pos
  local buf_common

  if buf_existed then
    cwd, cursor_pos, prev_buf = switch_buffer(buf_existed, win, prev_buf)
    buf_common = buf_existed
  elseif default_buf and vim.api.nvim_buf_is_valid(default_buf) then
    cwd, cursor_pos, prev_buf = switch_buffer(default_buf, win, prev_buf)
    buf_common = default_buf
  else
    default_buf = vim.api.nvim_create_buf(false, true)
    cwd = vim.fn.getcwd(0)
    view.create_default_buf(default_buf)
    buf_common = default_buf
  end

  set_view(buf_common, win, cwd, cursor_pos, prev_buf)
end

function M.brand_new_buffer()
  local win = vim.api.nvim_get_current_win()
  local buf_existed = window.find_buf_in(win)
  if buf_existed then
    vim.cmd "tabnew"
    win = vim.api.nvim_get_current_win()
  end
  local new_buf = vim.api.nvim_create_buf(false, true)
  local cwd = vim.fn.getcwd(0)
  local cursor_pos
  local prev_buf = vim.api.nvim_get_current_buf()

  view.create_new_buf(new_buf)

  set_view(new_buf, win, cwd, cursor_pos, prev_buf)
end

function M.setup(args)
  config.default = vim.tbl_deep_extend("force", config.default, args or {})
  require("nvf.highlight").setup()

  nvf_group = vim.api.nvim_create_augroup("Nvf", { clear = true })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = nvf_group,
    callback = function(ev)
      local win = tonumber(ev.match)
      local winbuf = window.find_buf_in(win)
      if win and winbuf and (winbuf ~= default_buf) then
        window.clear(win)
        buffer.clear(winbuf)
        cursor.clear(winbuf)
        vim.cmd.bwipeout(winbuf)
      end
    end,
  })
end

return M
