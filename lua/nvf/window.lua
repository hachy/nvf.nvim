local Window = {}

local list = {}

function Window.new(win, buf, prev_buf)
  list[win] = { buf = buf, prev_buf = prev_buf }
end

function Window.get_prev_buf(win)
  return list[win].prev_buf
end

return Window
