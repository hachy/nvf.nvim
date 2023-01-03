# nvf.nvim

Minimal file explorer for Neovim.

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
- `.` : Toggle visibility of hidden files
- `N` : Add a file
- `K` : Add a directory
- `R` : Rename
- `D` : Delete
- `c` : Copy
- `p` : Paste

## Custom configuration

```lua
require('nvf').setup({
  show_hidden_files = false,
  mappings = {
    ["q"] = "require('nvf.view').quit()",
    ["l"] = "require('nvf.view').open()",
    ["h"] = "require('nvf.view').cd()",
    ["."] = "require('nvf.view').toggle_hidden_files()",
    ["N"] = "require('nvf.file').create_file()",
    ["K"] = "require('nvf.file').create_directory()",
    ["R"] = "require('nvf.file').rename()",
    ["D"] = "require('nvf.file').delete()",
    ["c"] = "require('nvf.file').copy()",
    ["p"] = "require('nvf.file').paste()",
  },
})
```

### Special Thanks

Ideas inspired from [defx.nvim](https://github.com/Shougo/defx.nvim)
