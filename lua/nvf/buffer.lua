local M = {}

local list = {}

function M.new(buf, cwd, expanded_folders)
  list[buf] = { buf = buf, cwd = cwd, expanded_folders = expanded_folders }
end

function M.set_cwd(buf, cwd)
  list[buf].cwd = cwd
end

function M.get_cwd(buf)
  return list[buf].cwd
end

function M.get_expanded_folders(buf)
  if list[buf] ~= nil then
    return list[buf].expanded_folders
  end
  return nil
end

function M.mark_expand_or_collapse(buf, absolute_path)
  local t = list[buf].expanded_folders
  for i, v in ipairs(t) do
    if v == absolute_path then
      table.remove(t, i)
      return
    end
  end
  table.insert(t, absolute_path)
end

function M.exists_expanded_folders(buf, absolute_path)
  local t = list[buf].expanded_folders
  if t == nil then
    return false
  end
  for _, v in ipairs(t) do
    if v == absolute_path then
      return true
    end
  end
  return false
end

function M.clear(buf)
  list[buf] = nil
end

return M
