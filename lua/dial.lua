return {
    -- 以下はユーザがいじらず、参照することだけを想定しているもの。

    -- 処理全般に用いられる便利な関数が集まっている。
    util = require("dial/util"),
    -- augends の生成に用いられるテンプレートのような役割を持った関数が集まっている。
    common = require("dial/common"),
    -- インクリメント/デクリメントのための機能（コマンド）を提供する。
    cmd = require("dial/cmd"),

    -- 以下はユーザが変更することを想定しているもの。

    -- 設定値を格納する。
    cfg = require("dial/default"),
    -- デフォルトで定義される augends を提供する。
    augends = require("dial/augends"),
}
