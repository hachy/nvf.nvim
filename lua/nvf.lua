local config = require "nvf.config"
local buffer = require "nvf.buffer"
local window = require "nvf.window"
local cursor = require "nvf.cursor"
local view = require "nvf.view"

local M = {}

local default_buf

local function set_mappings(mappings)
  for k, v in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(0, "n", k, "<cmd>lua " .. v .. "<cr>", {
      nowait = true,
      noremap = true,
      silent = true,
    })
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
  view.redraw(buf, cwd)

  buffer.new(buf, cwd)
  window.new(win, buf, prev_buf)

  cursor.set(buf, cwd, cursor_pos or { 2, 0 })

  set_mappings(config.default.mappings)
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

function M.new_buf_in_win()
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
end

return M
