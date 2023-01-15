local et = require("dial.extras")

describe("Test functions in module extras", function()


  describe("Test concat_lists", function()
    it("concat_lists works with more than 2 lists", function()
      assert.are.same(et.concat_lists({ 1 }, { 2 }, { 3, 4 }), { 1, 2, 3, 4 })
    end)
  end)

  describe("Test _resolve_ft", function()
    it("If there is no group for the current ft, resolve 'default'", function()
      vim.o.filetype = "python"

      require("dial.config").augends:register_group {}
      assert.are.same(et._resolve_ft(), "default")
    end)

    it("if there is then return ft", function()

      require("dial.config").augends:register_group { python = {} }

      require("dial.extras")
      vim.o.filetype = "python"
      assert.are.same(et._resolve_ft(), "python")

    end)
  end)
end)
