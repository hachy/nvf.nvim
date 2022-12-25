local Cursor = {}

local list = {}

function Cursor.new(buf, dir, pos)
  local obj = { buf = buf, dir = dir, pos = pos }
  for i, t in pairs(list) do
    if t.buf == buf and t.dir == dir then
      list[i] = nil
    end
  end
  table.insert(list, obj)
  return setmetatable(obj, { __index = Cursor })
end

function Cursor.get(buf, dir)
  for _, t in pairs(list) do
    if t.buf == buf and t.dir == dir then
      return t.pos
    end
  end
end

function Cursor.set(buf, dir, default_pos)
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

return Cursor
