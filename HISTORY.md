# Changelog

## Unreleased

### New Features

* add options to augend 'date'
    * `custom_date_elements`
    * `clamp`
    * `end_sensitive`

## 0.4.0

### New Features

* add augend: paren ([#15](https://github.com/monaqa/dial.nvim/pull/15))
* add augend: case ([#26](https://github.com/monaqa/dial.nvim/pull/26), [#33](https://github.com/monaqa/dial.nvim/pull/33))
* support comma-separated number or other ([#16](https://github.com/monaqa/dial.nvim/pull/16))
* re-implement augend markdown_header ([#21](https://github.com/monaqa/dial.nvim/pull/21))
* add alias: German date formats and weekdays ([#24](https://github.com/monaqa/dial.nvim/pull/24), by @f1rstlady)
* add public config API for 'date' augend ([#35](https://github.com/monaqa/dial.nvim/pull/35)):
    * pattern
    * default_kind
    * only_valid
    * word

### Fixes

* Fix document ([#22](https://github.com/monaqa/dial.nvim/pull/22), by @ktakayama)

### Deprecates

* `augend.date.alias["%Y/%m/%d"]`
* `augend.date.alias["%m/%d/%Y"]`
* `augend.date.alias["%d/%m/%Y"]`
* `augend.date.alias["%m/%d/%y"]`
* `augend.date.alias["%d/%m/%y"]`
* `augend.date.alias["%m/%d"]`
* `augend.date.alias["%-m/%-d"]`
* `augend.date.alias["%Y-%m-%d"]`
* `augend.date.alias["%Y年%-m月%-d日"]`
* `augend.date.alias["%Y年%-m月%-d日(%ja)"]`
* `augend.date.alias["%H:%M:%S"]`
* `augend.date.alias["%H:%M"]`

## 0.3.0

* **[BREAKING CHANGE]** change overall interface
* support dot repeating
* support specifying augends with expression register

## 0.2.0

* **[BREAKING CHANGE]** rename all augends
* **[BREAKING CHANGE]** change the directory structure
* add help file

## 0.1.0

* first release
