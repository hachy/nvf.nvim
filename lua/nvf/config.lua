local M = {}

M.default = {
  show_hidden_files = false,
  mappings = {
    ["q"] = "require('nvf.view').quit()",
    ["l"] = "require('nvf.view').open()",
    ["h"] = "require('nvf.view').cd()",
    ["N"] = "require('nvf.file').create_file()",
    ["K"] = "require('nvf.file').create_directory()",
    ["R"] = "require('nvf.file').rename()",
    ["D"] = "require('nvf.file').delete()",
    ["c"] = "require('nvf.file').copy()",
    ["p"] = "require('nvf.file').paste()",
  },
}

return M