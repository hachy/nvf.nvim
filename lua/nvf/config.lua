local M = {}

M.default = {
  show_hidden_files = false,
  mappings = {
    quit = "q",
    open = "l",
    up = "h",
    expand_or_collapse = "t",
    cwd = "^",
    home = "~",
    toggle_hidden_files = ".",
    create_file = "N",
    create_directory = "K",
    rename = "R",
    delete = "D",
    copy = "c",
    paste = "p",
    brand_new_buffer = "<Tab>",
  },
  indent = 1,
  signs = {
    directory = " + ",
    file = "   ",
    expanded = " - ",
  },
}

return M
