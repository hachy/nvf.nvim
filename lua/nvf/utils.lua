local M = {}

local sep = package.config:sub(1, 1)

M.sep = sep

function M.remove_trailing_slash(path)
  if string.sub(path, -1) == sep then
    return string.sub(path, 1, #path - 1)
  else
    return path
  end
end

function M.shallowcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else
    copy = orig
  end
  return copy
end

return M
