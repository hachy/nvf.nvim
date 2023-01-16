local Window = {}

local list = {}

function Window.new(win, buf, prev_buf)
  list[win] = { buf = buf, prev_buf = prev_buf }
end

function Window.get_prev_buf(win)
  return list[win].prev_buf
end

function Window.find_buf_in(win)
  if list[win] == nil then
    return nil
  else
    return list[win].buf
  end
end

function Window.clear(win)
  list[win] = nil
end

return Window
