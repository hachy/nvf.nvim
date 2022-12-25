local buffer = require "nvf.buffer"
local window = require "nvf.window"
local cursor = require "nvf.cursor"
local view = require "nvf.view"

local M = {}

local buf

M.config = {
  show_hidden_files = false,
  mappings = {
    ["q"] = "require('nvf.view').quit()",
    ["l"] = "require('nvf.view').open()",
    ["h"] = "require('nvf.view').cd()",
    ["N"] = "require('nvf.file').create_file()",
    ["K"] = "require('nvf.file').create_directory()",
    ["R"] = "require('nvf.file').rename()",
    ["D"] = "require('nvf.file').delete()",
  },
}

local function set_mappings(mappings)
  for k, v in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(0, "n", k, "<cmd>lua " .. v .. "<cr>", {
      nowait = true,
      noremap = true,
      silent = true,
    })
  end
end

function M.init()
  local win = vim.api.nvim_get_current_win()
  local prev_buf = vim.api.nvim_get_current_buf()
  local cwd
  local cursor_pos

  if buf and vim.api.nvim_buf_is_valid(buf) then
    if prev_buf == buf then
      prev_buf = window.get_prev_buf(win)
    end
    vim.api.nvim_set_current_buf(buf)

    if vim.fn.haslocaldir(1) == 1 then
      cwd = vim.fn.getcwd(0)
      view.create_buf(buf)
    else
      cwd = buffer.get_cwd(buf)
    end
    cursor_pos = cursor.get(buf, cwd)
  else
    buf = vim.api.nvim_create_buf(false, true)
    cwd = vim.fn.getcwd(0)
    view.create_buf(buf)
  end

  view.redraw(buf, cwd)

  buffer.new(buf, cwd)
  window.new(win, buf, prev_buf)

  cursor.set(buf, cwd, cursor_pos or { 2, 0 })

  set_mappings(M.config.mappings)
end

function M.setup(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

return M
