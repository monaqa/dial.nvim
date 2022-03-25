# Troubleshooting

## Upgrading from v0.2.0 to v0.3.0

With the update from 0.2.0 to 0.3.0, new features and augend have been implemented,
and at the same time, the configuration scripts are no longer compatible. You need to rewrite it.

Here is an example of rewriting the configuration.

* Example settings (old)
  ```lua
  local dial = require("dial")

  dial.config.searchlist.normal = {
      "number#decimal",
      "date#[%m/%d]",
      "char#alph#small#word",
  }
  ```

* Example settings (new)
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


### Correspondence of augend names

|Old (v0.2.0)                |New (v0.3.0)                              |
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
