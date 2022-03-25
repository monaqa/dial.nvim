# トラブルシューティング

## v0.2.0 から v0.3.0 へのアップデート

`0.2.0` から `0.3.0` へのアップデートにあたり、新機能や新たな augend が実装されたと同時に設定方法の互換性がなくなりました。

以下のように設定を書き換える必要があります。

* 設定例（旧）
  ```lua
  local dial = require("dial")

  dial.config.searchlist.normal = {
      "number#decimal",
      "date#[%m/%d]",
      "char#alph#small#word",
  }
  ```

* 設定例（新）
  ```lua
  local augend = require("dial.augend")

  require("dial.config").augends:register_group{
    default = {
      augend.integer.alias.decimal,
      augend.date.alias["%m/%d"],
      augend.constant.alias.alpha,
    },
  }
  ```

### 被加数の新旧対応

|旧                          |新                                        |
|----------------------------|------------------------------------------|
|`number#decimal`            |`augend.integer.alias.decimal`            |
|`number#decimal#int`        |`augend.integer.alias.decimal`            |
|`number#decimal#fixed#zero` |not implemented                           |
|`number#decimal#fixed#space`|not implemented                           |
|`number#hex`                |`augend.integer.alias.hex`                |
|`number#octal`              |`augend.integer.alias.octal`              |
|`number#binary`             |`augend.integer.alias.binary`             |
|`date#[%Y/%m/%d]`           |`augend.date.alias["%Y/%m/%d"]`           |
|`date#[%m/%d]`              |`augend.date.alias["%m/%d"]`              |
|`date#[%-m/%-d]`            |`augend.date.alias["%-m/%-d"]`            |
|`date#[%Y-%m-%d]`           |`augend.date.alias["%Y-%m-%d"]`           |
|`date#[%Y年%-m月%-d日]`     |`augend.date.alias["%Y年%-m月%-d日"]`     |
|`date#[%Y年%-m月%-d日(%ja)]`|`augend.date.alias["%Y年%-m月%-d日(%ja)"]`|
|`date#[%H:%M:%S]`           |`augend.date.alias["%H:%M:%S"]`           |
|`date#[%H:%M]`              |`augend.date.alias["%H:%M"]`              |
|`date#[%ja]`                |`augend.constant.alias.ja_weekday`        |
|`date#[%jA]`                |`augend.constant.alias.ja_weekday_full`   |
|`char#alph#small#word`      |`augend.constant.alias.alpha`             |
|`char#alph#capital#word`    |`augend.constant.alias.Alpha`             |
|`char#alph#small#str`       |can be defined with `augend.constant.new` |
|`char#alph#capital#str`     |can be defined with `augend.constant.new` |
|`color#hex`                 |`augend.hexcolor.new{}`                   |
|`markup#markdown#header`    |`augend.misc.alias.markdown_header`       |
