# simple-tree.nvim

> | English | [中文](./README_ZH.md) |

<div align="center">
  <h3>A Tree Plugin  For <code>Neovim</code>.</h3>
  <img src="asset/image.png" alt="simple-tree" />
</div>

## Intro

`simple-tree` is a Neovim plugin to browse the file system

## Requirements

- Neovim 0.8+

- A patched font (see [nerd font](https://www.nerdfonts.com/))

## Install

With [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{'kkkkkHuang/simple-tree.nvim', opts = {--[[ your configuration]]}}
```

With [`packer.nvim`](https://github.com/wbthomason/packer.nvim):

```lua
require('packer').use { 'kkkkkHuang/simple-tree.nvim' }
```

With [`vim-plug`](https://github.com/junegunn/vim-plug):

```vim
Plug 'kkkkkHuang/simple-tree.nvim'
lua require("simple-tree").setup()
```

With [`Vundle.vim`](https://github.com/VundleVim/Vundle.vim):

```vim
Plugin 'kkkkkHuang/simple-tree.nvim'
```

With [`vim-pathogen`](https://github.com/tpope/vim-pathogen):

```shell
cd ~/.vim/bundle && \
git clone https://github.com/kkkkkHuang/simple-tree.nvim
```

With [`dein.vim`](https://github.com/Shougo/dein.vim):

```vim
call dein#add('kkkkkHuang/simple-tree.nvim')
```

## Usage

### Commands

`:TreeToggle` Open or close the tree

You can also bind it to a shortcut key, such as `<Leader>b`

```lua
vim.api.nvim_set_keymap('n', '<Leader>b', '<Cmd>TreeToggle<CR>', { noremap = true })
```

### Keymaps

| key         | description                                                   |
| ----------- | ------------------------------------------------------------- |
| `o`,`Enter` | If it is a folder, open or close it, if it is a file, edit it |
| `a`         | create the floder or file                                     |
| `r`         | rename the floder or file                                     |
| `d`         | delete the floder or file                                     |
| `c`         | copy the floder or file                                       |
| `m`         | move the floder or file                                       |
| `p`         | paste the floder or file                                      |

## Configure

Setup:

```lua
require("simple-tree").setup {
  -- width of the tree window
  width=30,

  -- Enable or disable auto focus on the current file
  auto_focus_file=true,

  -- You can customize the file icons
  file_icons={
    ['lua']="",
    ['py']="",
    -- ...
    ['default']=''
  },

  -- You can customize the folder icon
  folder_icons='',
  folder_open_icons='',

  -- show git status
  enable_git_status=true

}
```

## Other plugins setting

- [`bufferline.nvim`](https://github.com/akinsho/bufferline.nvim)

set sidebar offsets

```lua
require("bufferline").setup({
  options = {
    -- ...
    offsets = {
      {
        filetype = "simple-tree",
        text = "File Explorer",
        separator = true,
      },
      -- ...
    }
  }
})
```

When you use `bufferline.nvim` to close the buffer, it is possible that the entire `simple-tree` plugin will occupy the current buffer. You can change the configuration of `bufferline.nvim` like this to avoid that

```lua
require("bufferline").setup({
  options = {
    -- ...
    -- change the close command
    close_command = function(bufnum)
    	if bufnum == vim.fn.bufnr() then
        vim.cmd("bp")
    	end
    	vim.api.nvim_buf_delete(bufnum, { force = true })
    end,

    right_mouse_command = function(bufnum)
    	if bufnum == vim.fn.bufnr() then
        vim.cmd("bp")
    	end
    	vim.api.nvim_buf_delete(bufnum, { force = true })
    end,
    -- ...
  }
})
```

Similarly, if this happens with the command `:bd` to close buffer, you can also use the command `:bp | bd #` instead,This command means to switch to the buffer before the current window and delete the buffer of the last edited file
