local Buffer = {}

local list = {}

function Buffer.new(buf, cwd)
  list[buf] = { buf = buf, cwd = cwd }
end

function Buffer.set_cwd(buf, cwd)
  list[buf].cwd = cwd
end

function Buffer.get_cwd(buf)
  return list[buf].cwd
end

function Buffer.clear(buf)
  list[buf] = nil
end

return Buffer
