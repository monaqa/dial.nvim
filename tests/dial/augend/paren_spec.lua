local paren = require("dial.augend").paren

describe([[Test of paren between '...' and "...":]], function()
    local augend = paren.new {
        patterns = { { "'", "'" }, { '"', '"' } },
        nested = false,
        cyclic = true,
        escape_char = [[\]],
    }

    describe("find function", function()
        it("can find single- or double- quoted string", function()
            assert.are.same(augend:find([["foo"]], 1), { from = 1, to = 5 })
            assert.are.same(augend:find([['foo']], 1), { from = 1, to = 5 })
            assert.are.same(augend:find([[foo"bar"baz]], 1), { from = 4, to = 8 })
            assert.are.same(augend:find([[foo"bar"baz]], 4), { from = 4, to = 8 })
            assert.are.same(augend:find([[foo"bar"baz]], 5), { from = 4, to = 8 })
            assert.are.same(augend:find([[foo"bar"baz]], 8), { from = 4, to = 8 })
            assert.are.same(augend:find([[foo"bar"baz]], 9), nil)
            assert.are.same(augend:find([[foo""baz]], 1), { from = 4, to = 5 })
        end)
        it("returns nil when no string literal appears", function()
            assert.are.same(augend:find([[foo bar]], 1), nil)
            assert.are.same(augend:find([[foo "bar]], 1), nil)
            assert.are.same(augend:find([[foo 'bar"]], 1), nil)
        end)
        it("considers escape character", function()
            assert.are.same(augend:find([[foo"bar\"baz"]], 1), { from = 4, to = 13 })
            assert.are.same(augend:find([[foo'bar\'baz']], 1), { from = 4, to = 13 })
            assert.are.same(augend:find([[foo'bar\"baz']], 1), { from = 4, to = 13 })
            assert.are.same(augend:find([[foo'bar\nbaz']], 1), { from = 4, to = 13 })
            assert.are.same(augend:find([[foo'bar\'baz"]], 1), nil)
            assert.are.same(augend:find([[foo"bar\\"baz"]], 1), { from = 4, to = 10 })
        end)
        it("handle multiple quote areas", function()
            assert.are.same(augend:find([[a"b"c"b"a]], 1), { from = 2, to = 4 })
            assert.are.same(augend:find([[a"b"c"b"a]], 4), { from = 2, to = 4 })
            assert.are.same(augend:find([[a"b"c"b"a]], 5), { from = 6, to = 8 })
            assert.are.same(augend:find([[a"b"c"b"a]], 8), { from = 6, to = 8 })
            assert.are.same(augend:find([[a"b'c'b"a]], 1), { from = 2, to = 8 })
            assert.are.same(augend:find([[a"b'c'b"a]], 4), { from = 4, to = 6 })
        end)
    end)

    describe("add function", function()
        it("can convert single-quote to double and vice versa", function()
            assert.are.same(augend:add([['foo']], 1, 1), { text = [["foo"]], cursor = 5 })
            assert.are.same(augend:add([["foo"]], -1, 1), { text = [['foo']], cursor = 5 })
            assert.are.same(augend:add([['fo\'o']], 1, 1), { text = [["fo\'o"]], cursor = 7 })
        end)
        it("has cyclic behavior", function()
            assert.are.same(augend:add([['foo']], -1, 1), { text = [["foo"]], cursor = 5 })
            assert.are.same(augend:add([["foo"]], 1, 1), { text = [['foo']], cursor = 5 })
            assert.are.same(augend:add([["foo"]], 2, 1), { text = [["foo"]], cursor = 5 })
            assert.are.same(augend:add([["foo"]], 3, 1), { text = [['foo']], cursor = 5 })
        end)
    end)
end)

describe("Test of brackets `()`, `[]`, and `{}`:", function()
    local augend = paren.new {
        patterns = {
            { "(", ")" },
            { "[", "]" },
            { "{", "}" },
        },
        nested = true,
        cyclic = true,
    }

    describe("find function", function()
        it("can find brackets", function()
            assert.are.same(augend:find("foo(bar)", 1), { from = 4, to = 8 })
            assert.are.same(augend:find("foo[bar]", 1), { from = 4, to = 8 })
            assert.are.same(augend:find("foo{bar}", 1), { from = 4, to = 8 })
            assert.are.same(augend:find("foo(bar), bar[baz].", 1), { from = 4, to = 8 })
            assert.are.same(augend:find("foo(bar), bar[baz].", 4), { from = 4, to = 8 })
            assert.are.same(augend:find("foo(bar), bar[baz].", 8), { from = 4, to = 8 })
            assert.are.same(augend:find("foo(bar), bar[baz].", 9), { from = 14, to = 18 })
            assert.are.same(augend:find("foo(bar), bar[baz].", 14), { from = 14, to = 18 })
            assert.are.same(augend:find("foo(bar), bar[baz].", 18), { from = 14, to = 18 })
            assert.are.same(augend:find("foo(bar), bar[baz].", 19), nil)
            assert.are.same(augend:find("foo(bar]", 1), nil)
            assert.are.same(augend:find("foo(bar])", 1), { from = 4, to = 9 })
        end)
        it("considers nested brackets", function()
            assert.are.same(augend:find("foo({true}, 1) + 1", 1), { from = 4, to = 14 })
            assert.are.same(augend:find("foo({true}, 1) + 1", 4), { from = 4, to = 14 })
            assert.are.same(augend:find("foo({true}, 1) + 1", 5), { from = 5, to = 10 })
            assert.are.same(augend:find("foo({true}, 1) + 1", 10), { from = 5, to = 10 })
            assert.are.same(augend:find("foo({true}, 1) + 1", 11), { from = 4, to = 14 })
            assert.are.same(augend:find("foo({true}, 1) + 1", 14), { from = 4, to = 14 })
            assert.are.same(augend:find("foo({true}, 1) + 1", 15), nil)
            assert.are.same(augend:find("foo{{true}, 1} + 1", 1), { from = 4, to = 14 })
            assert.are.same(augend:find("foo{{true}, 1} + 1", 4), { from = 4, to = 14 })
            assert.are.same(augend:find("foo{{true}, 1} + 1", 5), { from = 5, to = 10 })
            assert.are.same(augend:find("foo{{true}, 1} + 1", 10), { from = 5, to = 10 })
            assert.are.same(augend:find("foo{{true}, 1} + 1", 11), { from = 4, to = 14 })
            assert.are.same(augend:find("foo{{true}, 1} + 1", 14), { from = 4, to = 14 })
            assert.are.same(augend:find("foo{{true}, 1} + 1", 15), nil)
            assert.are.same(augend:find("foo(bar[)baz]", 1), { from = 4, to = 9 })
            assert.are.same(augend:find("foo(bar[)baz]", 4), { from = 4, to = 9 })
            assert.are.same(augend:find("foo(bar[)baz]", 5), { from = 4, to = 9 })
            assert.are.same(augend:find("foo(bar[)baz]", 8), { from = 8, to = 13 })
            assert.are.same(augend:find("foo(bar[)baz]", 9), { from = 8, to = 13 })
            assert.are.same(augend:find("foo(bar[)baz]", 10), { from = 8, to = 13 })
        end)
    end)

    describe("add function", function()
        it("can convert brackets", function()
            assert.are.same(augend:add("(foo)", 1, 1), { text = "[foo]", cursor = 5 })
            assert.are.same(augend:add("[foo]", 1, 1), { text = "{foo}", cursor = 5 })
            assert.are.same(augend:add("(foo)", 2, 1), { text = "{foo}", cursor = 5 })
            assert.are.same(augend:add("[foo]", -1, 1), { text = "(foo)", cursor = 5 })
            assert.are.same(augend:add("{foo}", -2, 1), { text = "(foo)", cursor = 5 })
        end)
        it("has cyclic behavior", function()
            assert.are.same(augend:add("{foo}", 1, 1), { text = "(foo)", cursor = 5 })
            assert.are.same(augend:add("(foo)", 3, 1), { text = "(foo)", cursor = 5 })
            assert.are.same(augend:add("(foo)", -1, 1), { text = "{foo}", cursor = 5 })
            assert.are.same(augend:add("(foo)", -3, 1), { text = "(foo)", cursor = 5 })
        end)
    end)
end)

describe([[Test of paren between Rust-style str literal:]], function()
    local augend = paren.new {
        patterns = {
            { '"', '"' },
            { 'r#"', '"#' },
            { 'r##"', '"##' },
            { 'r###"', '"###' },
        },
        nested = false,
        cyclic = false,
    }

    describe("find function", function()
        it("can find string literals", function()
            assert.are.same(augend:find([["foo"]], 1), { from = 1, to = 5 })
            assert.are.same(augend:find([[r#"foo"#]], 1), { from = 1, to = 8 })
            assert.are.same(augend:find([[r##"foo"##]], 1), { from = 1, to = 10 })
            assert.are.same(augend:find([[four##"foo"##]], 1), { from = 4, to = 13 })
            assert.are.same(augend:find([[r##"foo"#]], 1), { from = 4, to = 8 })
            assert.are.same(augend:find([[r##"foo"#bar"##]], 1), { from = 1, to = 15 })
        end)
        it("behaves naturally with respect to cursor", function()
            assert.are.same(augend:find([[println!(r##"foo"##);]], 1), { from = 10, to = 19 })
            assert.are.same(augend:find([[println!(r##"foo"##);]], 9), { from = 10, to = 19 })
            assert.are.same(augend:find([[println!(r##"foo"##);]], 10), { from = 10, to = 19 })
            assert.are.same(augend:find([[println!(r##"foo"##);]], 11), { from = 10, to = 19 })
            -- TODO: is this natural?
            assert.are.same(augend:find([[println!(r##"foo"##);]], 13), { from = 13, to = 17 })
            assert.are.same(augend:find([[println!(r##"foo"##);]], 14), { from = 13, to = 17 })
            assert.are.same(augend:find([[println!(r##"foo"##);]], 17), { from = 13, to = 17 })
            assert.are.same(augend:find([[println!(r##"foo"##);]], 18), { from = 10, to = 19 })
            assert.are.same(augend:find([[println!(r##"foo"##);]], 19), { from = 10, to = 19 })
            assert.are.same(augend:find([[println!(r##"foo"##);]], 21), nil)
        end)
        it("returns nil when no string literal appears", function()
            assert.are.same(augend:find([[r#"foo#]], 1), nil)
        end)
    end)

    describe("add function", function()
        it("can convert quotes", function()
            assert.are.same(augend:add([["foo"]], 1, 1), { text = [[r#"foo"#]], cursor = 8 })
            assert.are.same(augend:add([["foo"]], 2, 1), { text = [[r##"foo"##]], cursor = 10 })
            assert.are.same(augend:add([["foo"]], 3, 1), { text = [[r###"foo"###]], cursor = 12 })
            assert.are.same(augend:add([[r#"foo"#]], 1, 1), { text = [[r##"foo"##]], cursor = 10 })
            assert.are.same(augend:add([[r#"foo"#]], -1, 1), { text = [["foo"]], cursor = 5 })
            assert.are.same(augend:add([[r###"foo"###]], -2, 1), { text = [[r#"foo"#]], cursor = 8 })
        end)
        it("does not have cyclic behavior", function()
            assert.are.same(augend:add([["foo"]], -1, 1), { text = [["foo"]], cursor = 5 })
            assert.are.same(augend:add([[r#"foo"#]], -2, 1), { text = [["foo"]], cursor = 5 })
            assert.are.same(augend:add([["foo"]], 4, 1), { text = [[r###"foo"###]], cursor = 12 })
        end)
    end)
end)
