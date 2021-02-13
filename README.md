# dial.nvim

**NOTICE: This plugin is work-in-progress yet. User interface is subject to change without notice.**

Extended increment/decrement plugin for [Neovim](https://github.com/neovim/neovim).
Mainly written in Lua.

![demo.gif](https://github.com/monaqa/dial.nvim/wiki/fig/dial-demo.gif)


## Features

* Increment/decrement various number and other things
  * decimal/hex/octal/binary natural integers
  * decimal integers (including negative number)
  * date
  * alphabet
  * hex colors
  * markdown header

## Similar plugins

* [tpope/vim-speeddating](https://github.com/tpope/vim-speeddating)

## Installation

If you use `vim-plug`:
```vim
Plug 'monaqa/dial.nvim'
```

## Usage

This plugin does not provide any default key-mapping.
To use this plugin, assign the plugin key-mapping to the key you like, as shown below:

```vim
nmap <C-a> <Plug>(dial-increment)
nmap <C-x> <Plug>(dial-decrement)
vmap <C-a> <Plug>(dial-increment)
vmap <C-x> <Plug>(dial-decrement)
vmap g<C-a> <Plug>(dial-increment-additional)
vmap g<C-x> <Plug>(dial-decrement-additional)
```

## Configuration

In this plugin, the target to increment/decrement is called **augend**.
In `dial.nvim`, you can operate on multiple types of augend.

|Augend Name                  |Explanation                                      |Examples                           |
|-----------------------------|:------------------------------------------------|:----------------------------------|
|`number#decimal`             |decimal natural number                           |`0`, `1`, ..., `9`, `10`, `11`, ...|
|`number#decimal#int`         |decimal integer (including negative number)      |`0`, `314`, `-1592`, ...           |
|`number#decimal#fixed#zero`  |fixed-digit decimal number (`0` padding)         |`00`, `01`, ..., `11`, ..., `99`   |
|`number#decimal#fixed#space` |fixed-digit decimal number (half space padding)  |`␣0`, `␣1`, ..., `11`, ..., `99`   |
|`number#hex`                 |hex natural number                               |`0x00`, `0x3f3f`, ...              |
|`number#octal`               |octal natural number                             |`000`, `011`, `024`, ...           |
|`number#binary`              |binary natural number                            |`0b0101`, `0b11001111`, ...        |
|`date#[%Y/%m/%d]`            |Date in the format `%Y/%m/%d` (`0` padding)      |`2021/01/04`, ...                  |
|`date#[%m/%d]`               |Date in the format `%m/%d` (`0` padding)         |`01/04`, `02/28`, `12/25`, ...     |
|`date#[%-m/%-d]`             |Date in the format `%-m/%-d` (no paddings)       |`1/4`, `2/28`, `12/25`, ...        |
|`date#[%Y-%m-%d]`            |Date in the format `%Y-%m-%d` (`0` padding)      |`2021-01-04`, ...                  |
|`date#[%Y年%-m月%-d日]`      |Date in the format `%Y年%-m月%-d日` (no paddings)|`2021年1月4日`, ...                |
|`date#[%Y年%-m月%-d日(%ja)]` |Date in the format `%Y年%-m月%-d日(%ja)`         |`2021年1月4日(月)`, ...            |
|`date#[%H:%M:%S]`            |Time in the format `%H:%M:%S`                    |`14:30:00`, ...                    |
|`date#[%H:%M]`               |Time in the format `%H:%M`                       |`14:30`, ...                       |
|`date#[%ja]`                 |Japanese weekday                                 |`月`, `火`, ..., `土`, `日`        |
|`date#[%jA]`                 |Japanese full weekday                            |`月曜日`, `火曜日`, ..., `日曜日`  |
|`char#alph#small#word`       |Lowercase alphabet letter (word)                 |`a`, `b`, `c`, ..., `z`            |
|`char#alph#capital#word`     |Uppercase alphabet letter (word)                 |`A`, `B`, `C`, ..., `Z`            |
|`char#alph#small#str`        |Lowercase alphabet letter (string)               |`a`, `b`, `c`, ..., `z`            |
|`char#alph#capital#str`      |Uppercase alphabet letter (string)               |`A`, `B`, `C`, ..., `Z`            |
|`color#hex`                  |hex triplet                                      |`#00ff00`, `#ababab`, ...          |
|`markup#markdown#header`     |Markdown Header                                  |`#`, `##`, ..., `######`           |

To specify the list of augend you want to operate on, write the following code in your `.vimrc`:

```lua
lua << EOF
local dial = require("dial")

dial.config.searchlist.normal = {
    "number#decimal",
    "number#hex",
    "number#binary",
    "date#[%Y/%m/%d]",
    "markup#markdown#header",
}
EOF
```

`dial.searchlist.normal` is the list of available augends in normal mode,
and `dial.augends` is a submodule that stores augend, which is provided by default.

The default set of available augends are shown here:

|Augend Name                  |Normal mode|Visual mode|
|:----------------------------|:---------:|:---------:|
|`number#decimal`             |✓          |✓          |
|`number#decimal#int`         |           |           |
|`number#decimal#fixed#zero`  |           |           |
|`number#decimal#fixed#space` |           |           |
|`number#hex`                 |✓          |✓          |
|`number#octal`               |           |           |
|`number#binary`              |✓          |✓          |
|`date#[%Y/%m/%d]`            |✓          |✓          |
|`date#[%m/%d]`               |✓          |✓          |
|`date#[%-m/%-d]`             |           |           |
|`date#[%Y-%m-%d]`            |✓          |✓          |
|`date#[%Y年%-m月%-d日]`      |           |           |
|`date#[%Y年%-m月%-d日(%ja)]` |           |           |
|`date#[%H:%M:%S]`            |           |           |
|`date#[%H:%M]`               |✓          |✓          |
|`date#[%ja]`                 |           |           |
|`date#[%jA]`                 |✓          |✓          |
|`char#alph#small#word`       |           |✓          |
|`char#alph#capital#word`     |           |✓          |
|`char#alph#small#str`        |           |           |
|`char#alph#capital#str`      |           |           |
|`color#hex`                  |✓          |✓          |
|`markup#markdown#header`     |           |           |

If you just want to add a few of augends into default `searchlist`, you can also write the configuration like this:

```lua
lua << EOF
local dial = require("dial")

table.insert(dial.config.searchlist.normal, "markup#markdown#header")
EOF
```

Changing `dial.serchlist.visual` table, you can also customize the behavior of `<C-a>` / `<C-x>` in visual mode.

The list of currently enabled augends can be checked with `:DialShowSearchList` command.

## User extension

You can even define your own augend.
Augend is a table that contains two fields (`name` and `desc`) and two methods (`find` and `add`).
For example, the following code defines `my_augend`, which enables you to double or halve the natural number.

```lua
lua << EOF
local dial = require("dial")

local my_augend = {
    desc = "double or halve the number. (1 <-> 2 <-> 4 <-> 8 <-> ...)",

    find = dial.common.find_pattern("%d+"),
    add = function(cursor, text, addend)
        local n = tonumber(text)
        n = math.floor(n * (2 ^ addend))
        text = tostring(n)
        cursor = #text
        return cursor, text
    end
}

dial.augends["custom#my_augend"] = my_augend

dial.config.searchlist.normal = {
    "custom#my_augend"
}
EOF
```

If you want to toggle `true` / `false` with `dial.nvim`'s command, try this:

```lua
dial.augends["custom#boolean"] = dial.common.enum_cyclic{
    name = "boolean",
    strlist = {"true", "false"},
}
table.insert(dial.config.searchlist.normal, "custom#boolean")
```

## Changelog

See [HISTORY](./HISTORY.md).

## TODO

* [ ] Write help file
* [x] Command for visual-block mode
