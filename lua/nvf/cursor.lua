local M = {}

local list = {}

function M.new(buf, dir, pos)
  local obj = { buf = buf, dir = dir, pos = pos }
  for i, t in pairs(list) do
    if t.buf == buf and t.dir == dir then
      list[i] = nil
    end
  end
  table.insert(list, obj)
  return setmetatable(obj, { __index = M })
end

function M.get(buf, dir)
  for _, t in pairs(list) do
    if t.buf == buf and t.dir == dir then
      return t.pos
    end
  end
end

function M.set(buf, dir, default_pos)
  local pos = default_pos
  for _, t in pairs(list) do
    if t.buf == buf and t.dir == dir then
      pos = t.pos
      break
    end
  end
  local wins = vim.api.nvim_list_wins()
  for _, win_id in ipairs(wins) do
    local buf_id = vim.api.nvim_win_get_buf(win_id)
    if buf == buf_id then
      local ok = pcall(vim.api.nvim_win_set_cursor, win_id, pos)
      if not ok then
        vim.api.nvim_win_set_cursor(win_id, { 1, 0 })
      end
    end
  end
end

function M.clear(buf)
  for i, v in ipairs(list) do
    if v.buf == buf then
      list[i] = nil
    end
  end
end

return M
