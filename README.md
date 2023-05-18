# nvf.nvim

Minimal file explorer for Neovim.

<img width="702" alt="nvf" src="https://user-images.githubusercontent.com/1613863/215327603-703c1766-bf39-4706-a0d6-24ef1a9afd25.png">

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'hachy/nvf.nvim'
```

## Setup

Add this to your init.lua

```lua
require("nvf").setup({})
```

or init.vim

```vim
lua require("nvf").setup({})
```

## Usage

- `:Nvf` Open the default explorer. If there is another explorer in the window, open it first.

- `:NvfNew` Open another explorer that is not synchronized with the default.

This is the recommended keymap.

```lua
vim.keymap.set("n", "<Space>f", "<Cmd>Nvf<CR>")
```

## Default mappings

- `q` : Quit the buffer
- `l` : Open a file or directory under the cursor
- `h` : Move to the parent directory
- `t` : Expand or collapse tree
- `^` : Move to current working directory
- `~` : Move to home directory
- `.` : Toggle visibility of hidden files
- `N` : Add a file
- `K` : Add a directory
- `R` : Rename
- `D` : Delete
- `c` : Copy
- `p` : Paste
- `<Tab>` : Open a brand new buffer

## Custom configuration

```lua
require("nvf").setup {
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
}
```

### Special Thanks

Ideas inspired from [defx.nvim](https://github.com/Shougo/defx.nvim)
