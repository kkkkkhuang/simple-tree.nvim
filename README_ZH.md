
# simple-tree.nvim 
> [英文](./README_ZH.md) | 中文 

<div align="center">
  <h3>一个用于 <code>Neovim</code> 的目录树插件。</h3>
  <img src="asset/image.png" alt="simple-tree" />
</div>


## 介绍

`simple-tree` 是一个 Neovim 插件，用于浏览文件系统。

## 要求

- 此插件仅在 Neovim 0.5 或更高版本中工作。
- [nerd 字体](https://www.nerdfonts.com/) 是可选的，用于显示文件图标。如果你需要它，请将其配置为你终端模拟器的字体。

## 安装

使用 [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{'kkkkkHuang/simple-tree.nvim', opts = {--[[ 你的配置]]}}
```

使用 [`packer.nvim`](https://github.com/wbthomason/packer.nvim):

```lua
require('packer').use { 'kkkkkHuang/simple-tree.nvim' }
```

使用 [`paq-nvim`](https://github.com/savq/paq-nvim):

```lua
require("paq") { 'kkkkkHuang/simple-tree.nvim' }
```

使用 [`vim-plug`](https://github.com/junegunn/vim-plug):

```vim
Plug 'kkkkkHuang/simple-tree.nvim'
lua require("simple-tree").setup()
```

使用 [`Vundle.vim`](https://github.com/VundleVim/Vundle.vim):

```vim
Plugin 'kkkkkHuang/simple-tree.nvim'
```

使用 [`vim-pathogen`](https://github.com/tpope/vim-pathogen):

```shell
cd ~/.vim/bundle && \
git clone https://github.com/kkkkkHuang/simple-tree.nvim
```

使用 [`dein.vim`](https://github.com/Shougo/dein.vim):

```vim
call dein#add('kkkkkHuang/simple-tree.nvim')
```

## 使用

### 命令

`:TreeToggle` 打开或关闭目录树

### 快捷键

| 键         | 描述                                                   |
| ---------- | ------------------------------------------------------ |
| `o`, `Enter` | 打开或关闭文件夹，如果是文件则编辑它          |
| `a`        | 创建文件夹或文件                                       |
| `r`        | 重命名文件夹或文件                                     |
| `d`        | 删除文件夹或文件                                       |
| `c`        | 复制文件夹或文件                                       |
| `m`        | 移动文件夹或文件                                       |
| `p`        | 粘贴文件夹或文件                                       |

## 配置

设置：

```lua
require("simple-tree").setup {
  -- 目录树窗口的宽度
  width=30,

  -- 启用或禁用自动聚焦到当前文件
  auto_focus_file=true,

  -- 你可以自定义文件图标
  file_icons={
    ['lua']="",
    ['py']="",
    -- ...
    ['default']=''
  },

  -- 你可以自定义文件夹图标
  folder_icons='',
  folder_open_icons='',
}
```