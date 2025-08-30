# dial.nvim

## 概要

[Neovim](https://github.com/neovim/neovim) の数値増減機能を拡張する Lua 製プラグイン。
既存の `<C-a>` や `<C-x>` コマンドを拡張し、数値以外も増減・トグルできるようにします。

![demo.gif](https://github.com/monaqa/dial.nvim/wiki/fig/dial-demo-2.gif)

## 特徴

* 数値をはじめとする様々なものの増減
  * n 進数 (`2 <= n <= 36`) の整数
  * 小数
  * 日付・時刻
  * キーワードや演算子など、所定文字列のトグル
    * `true` ⇄ `false`
    * `&&` ⇄ `||`
    * `a` ⇄ `b` ⇄ ... ⇄ `z`
    * `日` ⇄ `月` ⇄ ... ⇄ `土` ⇄ `日` ⇄ ...
  * Hex color
  * SemVer
* VISUAL mode での `<C-a>` / `<C-x>` / `g<C-a>` / `g<C-x>` に対応
* 増減対象の柔軟な設定
  * 特定のファイルタイプでのみ有効なルールの設定
  * VISUAL モードでのみ有効なルールの設定
* カウンタに対応
* ドットリピートに対応

## 類似プラグイン

* [tpope/vim-speeddating](https://github.com/tpope/vim-speeddating)
* [Cycle.vim](https://github.com/zef/vim-cycle)
* [AndrewRadev/switch.vim](https://github.com/AndrewRadev/switch.vim)

## インストール

本プラグインには Neovim 0.11.0 以上が必要です。
好きなパッケージマネージャの指示に従うことでインストールできます。

## 使用方法

本プラグインはデフォルトではキーマッピングを設定/上書きしません。
本プラグインを有効にするには、いずれかのキーに以下のような割り当てを行う必要があります。

```vim
nnoremap  <C-a> <Plug>(dial-increment)
nnoremap  <C-x> <Plug>(dial-decrement)
nnoremap g<C-a> <Plug>(dial-g-increment)
nnoremap g<C-x> <Plug>(dial-g-decrement)
xnoremap  <C-a> <Plug>(dial-increment)
xnoremap  <C-x> <Plug>(dial-decrement)
xnoremap g<C-a> <Plug>(dial-g-increment)
xnoremap g<C-x> <Plug>(dial-g-decrement)
```

または Lua 上で以下のように設定することもできます。

```lua
vim.keymap.set("n", "<C-a>", function()
    require("dial.map").manipulate("increment", "normal")
end)
vim.keymap.set("n", "<C-x>", function()
    require("dial.map").manipulate("decrement", "normal")
end)
vim.keymap.set("n", "g<C-a>", function()
    require("dial.map").manipulate("increment", "gnormal")
end)
vim.keymap.set("n", "g<C-x>", function()
    require("dial.map").manipulate("decrement", "gnormal")
end)
vim.keymap.set("x", "<C-a>", function()
    require("dial.map").manipulate("increment", "visual")
end)
vim.keymap.set("x", "<C-x>", function()
    require("dial.map").manipulate("decrement", "visual")
end)
vim.keymap.set("x", "g<C-a>", function()
    require("dial.map").manipulate("increment", "gvisual")
end)
vim.keymap.set("x", "g<C-x>", function()
    require("dial.map").manipulate("decrement", "gvisual")
end)
```

## 設定方法

dial.nvim では操作対象を表す**被加数** (augend) と、複数の被加数をまとめた**グループ**を用いることで、増減させるルールを自由に設定することができます。

```lua
local augend = require("dial.augend")
require("dial.config").augends:register_group{
  -- グループ名を指定しない場合に用いられる被加数
  default = {
    augend.integer.alias.decimal,   -- nonnegative decimal number (0, 1, 2, 3, ...)
    augend.integer.alias.hex,       -- nonnegative hex number  (0x01, 0x1a1f, etc.)
    augend.date.alias["%Y/%m/%d"],  -- date (2022/02/19, etc.)
  },

  -- `mygroup` というグループ名を使用した際に用いられる被加数
  mygroup = {
    augend.integer.alias.decimal,
    augend.constant.alias.bool,    -- boolean value (true <-> false)
    augend.date.alias["%m/%d/%Y"], -- date (02/19/2022, etc.)
  }
}
```

* `"dial.config"` モジュールに存在する `augends:register_group` 関数を用いてグループを定義することができます。
  関数の引数には、グループ名をキー、被加数のリストを値とする辞書を指定します。

* 上の例で `augend` という名前のローカル変数に代入されている `"dial.augend"` モジュールでは、さまざまな被加数が定義されています。

以下のように **expression register** ([`:h @=`](https://neovim.io/doc/user/change.html#quote_=)) を用いると、増減対象のグループを指定できます。

```
"=mygroup<CR><C-a>
```

増減のたびに expression register を指定するのが面倒であれば、以下のようにマッピングすることも可能です。

```vim
nmap <Leader>a "=mygroup<CR><Plug>(dial-increment)
```

また、 Lua 上で以下のように記述すれば expression register を使わずにマッピングを設定できます。

```lua
vim.keymap.set("n", "<Leader>a", require("dial.map").inc_normal("mygroup"))
```

expression register などでグループ名を指定しなかった場合、`default` グループにある被加数がかわりに用いられます。

### 設定例

```lua
local augend = require("dial.augend")
require("dial.config").augends:register_group{
  default = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.date.alias["%Y/%m/%d"],
  },
  only_in_visual = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.date.alias["%Y/%m/%d"],
    augend.constant.alias.alpha,
    augend.constant.alias.Alpha,
  },
}

-- Use `only_in_visual` group only in VISUAL <C-a> / <C-x>
vim.keymap.set("x", "<C-a>", function()
    require("dial.map").manipulate("increment", "visual", "only_in_visual")
end)
vim.keymap.set("x", "<C-x>", function()
    require("dial.map").manipulate("decrement", "visual", "only_in_visual")
end)

require("dial.config").augends:on_filetype {
  typescript = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.constant.new{ elements = {"let", "const"} },
  },
}
```

## 被加数の種類と一覧

以下簡単のため、 `augend` という変数は以下のように定義されているものとします。

```lua
local augend = require("dial.augend")
```

### 整数

n 進数の整数 (`2 <= n <= 36`) を表します。 `augend.integer.new{ ...opts }` で使用できます。

```lua
require("dial.config").augends:register_group{
  default = {
    -- uppercase hex number (0x1A1A, 0xEEFE, etc.)
    augend.integer.new{
      radix = 16,
      prefix = "0x",
      natural = true,
      case = "upper",
    },
  },
}
```

### 日付

日付や時刻を表します。

```lua
require("dial.config").augends:register_group{
  default = {
    -- date with format `yyyy/mm/dd`
    augend.date.new{
        pattern = "%Y/%m/%d",
        default_kind = "day",
        -- if true, it does not match dates which does not exist, such as 2022/05/32
        only_valid = true,
        -- if true, it only matches dates with word boundary
        word = false,
    },
  },
}
```

`pattern` で指定する文字列には、以下のエスケープシーケンスを使用できます。

|文字列|意味                                                        |
|-----|-------------------------------------------------------------|
|`%Y` |4桁の西暦。 (e.g. `2022`)                                    |
|`%y` |西暦の下2桁。上2桁は `20` として解釈されます。 (e.g. `22`)   |
|`%m` |2桁の月。 (e.g. `09`)                                        |
|`%d` |2桁の日。 (e.g. `28`)                                        |
|`%H` |24時間で表示した2桁の時間。 (e.g. `15`)                      |
|`%I` |12時間で表示した2桁の時間。 (e.g. `03`)                      |
|`%M` |2桁の分。 (e.g. `05`)                                        |
|`%S` |2桁の秒。 (e.g. `08`)                                        |
|`%-y`|西暦の下2桁を1–2桁で表したもの。(e.g. `9` で `2009` 年を表す)|
|`%-m`|1–2桁の月。 (e.g. `9`)                                       |
|`%-d`|1–2桁の日。 (e.g. `28`)                                      |
|`%-H`|24時間で表示した1–2桁の時間。 (e.g. `15`)                    |
|`%-I`|12時間で表示した1–2桁の時間。 (e.g. `3`)                     |
|`%-M`|1–2桁の分。 (e.g. `5`)                                       |
|`%-S`|1–2桁の秒。 (e.g. `8`)                                       |
|`%a` |英語表記の短い曜日。 (`Sun`, `Mon`, ..., `Sat`)              |
|`%A` |英語表記の曜日。 (`Sunday`, `Monday`, ..., `Saturday`)       |
|`%b` |英語表記の短い月名。 (`Jan`, ..., `Dec`)                     |
|`%B` |英語表記の月名。 (`January`, ..., `December`)                |
|`%p` |`AM` または `PM`。                                           |
|`%J` |日本語表記の曜日。 (`日`, `月`, ..., `土`)                   |

### 定数

キーワードなどの決められた文字列をトグルします。 `augend.constant.new{ ...opts }` で使用できます。

```lua
require("dial.config").augends:register_group{
  default = {
    -- uppercase hex number (0x1A1A, 0xEEFE, etc.)
    augend.constant.new{
      elements = {"and", "or"},
      word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
      cyclic = true,  -- "or" is incremented into "and".
    },
    augend.constant.new{
      elements = {"&&", "||"},
      word = false,
      cyclic = true,
    },
  },
}
```

### hex color

`#000000` や `#ffffff` といった形式の RGB カラーコードを増減します。 `augend.hexcolor.new{ ...opts }` で使用できます。

```lua
require("dial.config").augends:register_group{
  default = {
    -- uppercase hex number (0x1A1A, 0xEEFE, etc.)
    augend.hexcolor.new{
      case = "lower",
    },
  },
}
```

### SemVer

Semantic version を増減します。後述のエイリアスを用います。
単なる非負整数のインクリメントとは以下の点で異なります。

- semver 文字列よりもカーソルが手前にあるときは、パッチバージョンが優先してインクリメントされます。
- マイナーバージョンの値が増加したとき、パッチバージョンの値は0にリセットされます。
- メジャーバージョンの値が増加したとき、マイナー・パッチバージョンの値は0にリセットされます。

### カスタム

ユーザ自身が増減ルールを定義したい場合には `augend.user.new{ ...opts }` を使用できます。

```lua
require("dial.config").augends:register_group{
  default = {
    -- uppercase hex number (0x1A1A, 0xEEFE, etc.)
    augend.user.new{
      find = require("dial.augend.common").find_pattern("%d+"),
      add = function(text, addend, cursor)
          local n = tonumber(text)
          n = math.floor(n * (2 ^ addend))
          text = tostring(n)
          cursor = #text
          return {text = text, cursor = cursor}
      end
    },
  },
}
```

### エイリアス

エイリアスはライブラリで予め定義された被加数です。 `new` 関数を用いることなく、そのまま使用できます。

```lua
require("dial.config").augends:register_group{
  default = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.date.alias["%Y/%m/%d"],
  },
}
```

エイリアスとして提供されている被加数は以下の通りです。

|Alias Name                                |Explanation                                      |Examples                           |
|------------------------------------------|-------------------------------------------------|-----------------------------------|
|`augend.integer.alias.decimal`            |decimal natural number                           |`0`, `1`, ..., `9`, `10`, `11`, ...|
|`augend.integer.alias.decimal_int`        |decimal integer (including negative number)      |`0`, `314`, `-1592`, ...           |
|`augend.integer.alias.hex`                |hex natural number                               |`0x00`, `0x3f3f`, ...              |
|`augend.integer.alias.octal`              |octal natural number                             |`0o00`, `0o11`, `0o24`, ...        |
|`augend.integer.alias.binary`             |binary natural number                            |`0b0101`, `0b11001111`, ...        |
|`augend.date.alias["%Y/%m/%d"]`           |Date in the format `%Y/%m/%d` (`0` padding)      |`2021/01/23`, ...                  |
|`augend.date.alias["%m/%d/%Y"]`           |Date in the format `%m/%d/%Y` (`0` padding)      |`23/01/2021`, ...                  |
|`augend.date.alias["%d/%m/%Y"]`           |Date in the format `%d/%m/%Y` (`0` padding)      |`01/23/2021`, ...                  |
|`augend.date.alias["%m/%d/%y"]`           |Date in the format `%m/%d/%y` (`0` padding)      |`01/23/21`, ...                    |
|`augend.date.alias["%d/%m/%y"]`           |Date in the format `%d/%m/%y` (`0` padding)      |`23/01/21`, ...                    |
|`augend.date.alias["%m/%d"]`              |Date in the format `%m/%d` (`0` padding)         |`01/04`, `02/28`, `12/25`, ...     |
|`augend.date.alias["%-m/%-d"]`            |Date in the format `%-m/%-d` (no paddings)       |`1/4`, `2/28`, `12/25`, ...        |
|`augend.date.alias["%Y-%m-%d"]`           |Date in the format `%Y-%m-%d` (`0` padding)      |`2021-01-04`, ...                  |
|`augend.date.alias["%Y年%-m月%-d日"]`     |Date in the format `%Y年%-m月%-d日` (no paddings)|`2021年1月4日`, ...                |
|`augend.date.alias["%Y年%-m月%-d日(%ja)"]`|Date in the format `%Y年%-m月%-d日(%ja)`         |`2021年1月4日(月)`, ...            |
|`augend.date.alias["%H:%M:%S"]`           |Time in the format `%H:%M:%S`                    |`14:30:00`, ...                    |
|`augend.date.alias["%H:%M"]`              |Time in the format `%H:%M`                       |`14:30`, ...                       |
|`augend.constant.alias.ja_weekday`        |Japanese weekday                                 |`月`, `火`, ..., `土`, `日`        |
|`augend.constant.alias.ja_weekday_full`   |Japanese full weekday                            |`月曜日`, `火曜日`, ..., `日曜日`  |
|`augend.constant.alias.bool`              |elements in boolean algebra (`true` and `false`) |`true`, `false`                    |
|`augend.constant.alias.alpha`             |Lowercase alphabet letter (word)                 |`a`, `b`, `c`, ..., `z`            |
|`augend.constant.alias.Alpha`             |Uppercase alphabet letter (word)                 |`A`, `B`, `C`, ..., `Z`            |
|`augend.semver.alias.semver`              |Semantic version                                 |`0.3.0`, `1.22.1`, `3.9.1`, ...    |

何も設定しなかった場合は以下の被加数が `default` グループの値としてセットされます。

- `augend.integer.alias.decimal`
- `augend.integer.alias.hex`
- `augend.date.alias["%Y/%m/%d"]`
- `augend.date.alias["%Y-%m-%d"]`
- `augend.date.alias["%m/%d"]`
- `augend.date.alias["%H:%M"]`
- `augend.constant.alias.ja_weekday_full`

## 更新履歴

[HISTORY](./HISTORY.md) を参照。

## Testing

[`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim) の `PlenaryBustedDirectory` を用いています。
