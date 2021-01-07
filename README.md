# dial.nvim

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

This plugin does not provide any default keymap.
To use this plugin, assign the plugin keymap to the key you like, as shown below:

```vim
nmap <C-a> <Plug>(dial-increment)
nmap <C-x> <Plug>(dial-decrement)
```

## Configuration

In this plugin, the target to increment/decrement is called **augend**.
In `dial.nvim`, you can operate on multiple types of augend.

To specify the list of augend you want to operate on, write the following code in your `.vimrc`:

```vim
lua << EOF
local dial = require("dial")

dial.searchlist = {
    dial.augends.number.decimal,
    dial.augends.number.hex,
    dial.augends.number.binary,
    dial.augends.date.date,
    dial.augends.markup.markdown_header,
}
EOF
```

`dial.searchlist` is the list of augend,
and `dial.augends` is a submodule that stores augend, which is provided by default.

|Augend Name             |Explanation                                |Examples                           |
|------------------------|-------------------------------------------|-----------------------------------|
|`number.decimal`        |decimal natural number                     |`0`, `1`, ..., `9`, `10`, `11`, ...|
|`number.hex`            |hex natural number                         |`0x00`, `0x3f3f`, ...              |
|`number.octal`          |octal natural number                       |`000`, `011`, `024`, ...           |
|`number.binary`         |binary natural number                      |`0b0101`, `0b11001111`, ...        |
|`number.decimal_integer`|decimal integer (including negative number)|`0`, `314`, `-1592`, ...           |
|`date.date`             |Date in the format `%Y/%m/%d`              |`2020/01/04`, `1970/01/01`, ...    |
|`date.weekday_ja`       |Japanese weekday                           |`月`, `火`, ..., `土`, `日`        |
|`char.alph_small`       |Lowercase alphabet letter (word)           |`a`, `b`, `c`, ..., `z`            |
|`char.alph_capital`     |Uppercase alphabet letter (word)           |`A`, `B`, `C`, ..., `Z`            |
|`color.hex`             |hex triplet                                |`#00ff00`, `#ababab`, ...          |
|`markup.markdown_header`|Markdown Header                            |`#`, `##`, ..., `######`           |

The list of currently enabled augends can be checked with `:DialShowSearchList` command.

## User extension

You can even define your own augend.
Augend is a table that contains two fields (`name` and `desc`) and two methods (`find` and `add`).
For example, the following code defines `my_augend`, which enables you to double or halve the natural number.

```vim
lua << EOF
local dial = require("dial")

local my_augend = {
    name = "my_augend",
    desc = "double or halve the number. (1 <-> 2 <-> 4 <-> 8 <-> ...)",

    find = dial.augends.common.find_pattern("%d+"),
    add = function(cursor, text, addend)
        local n = tonumber(text)
        n = math.floor(n * (2 ^ addend))
        text = tostring(n)
        cursor = #text
        return cursor, text
    end
}

dial.searchlist = {
    my_augend
}
EOF
```

## TODO

* Write help file
* User-friendly error notification
* Command for visual mode
* Command for visual-line mode
* More various data formats
