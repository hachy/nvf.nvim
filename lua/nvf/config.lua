local M = {}

M.default = {
  show_hidden_files = false,
  mappings = {
    ["q"] = "quit",
    ["l"] = "open",
    ["h"] = "up",
    ["t"] = "expand_or_collapse",
    ["^"] = "cwd",
    ["~"] = "home",
    ["."] = "toggle_hidden_files",
    ["N"] = "create_file",
    ["K"] = "create_directory",
    ["R"] = "rename",
    ["D"] = "delete",
    ["c"] = "copy",
    ["p"] = "paste",
    ["<Tab>"] = "brand_new_buffer",
  },
}

return M
