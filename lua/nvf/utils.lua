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

return M
