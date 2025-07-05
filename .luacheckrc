read_globals = { "vim" }

max_comment_line_length = false
codes = true

exclude_files = {}

ignore = {
    "111", -- setting non-standard global variable
    "113", -- accessing undefined variable
    "211", -- unused function
    "212", -- unused self
    "311", -- unused variable
    "431", -- shadow upvalue self
    "542", -- empty if branch
    "631", -- line is too long
}

read_globals = { "vim" }
