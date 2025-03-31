local M = {}

local list = {}

function M.new(win, buf, prev_buf)
  list[win] = { buf = buf, prev_buf = prev_buf }
end

function M.get_prev_buf(win)
  local pb = list[win].prev_buf
  if vim.fn.bufexists(pb) == 0 then
    local bl = vim.fn.getbufinfo { buflisted = 1 }
    for _, v in pairs(bl) do
      return v.bufnr
    end
  end
  return pb
end

function M.find_buf_in(win)
  if list[win] == nil then
    return nil
  else
    return list[win].buf
  end
end

function M.clear(win)
  list[win] = nil
end

return M
