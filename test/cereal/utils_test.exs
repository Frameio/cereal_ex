defmodule Cereal.UtilsTest do
  use ExUnit.Case

  alias Cereal.Utils

  describe "#normalize_includes/1" do
    test "will normalize a single include" do
      includes = "account"
      expected = [account: []]

      assert Utils.normalize_includes(includes) == expected
    end

    test "will normalize multiple includes" do
      includes = "account,user"
      expected = [user: [], account: []]

      assert Utils.normalize_includes(includes) == expected
    end

    test "will normalize a deep include" do
      includes = "account,account.user,account.user.parent"
      expected = [account: [user: [parent: []]]]

      assert Utils.normalize_includes(includes) == expected
    end

    test "will filter out strings that cannot safely become atoms" do
      includes = "account,account.user,account.thisdoesnotexist,account.parent"
      expected = [account: [parent: [], user: []]]

      assert Utils.normalize_includes(includes) == expected
    end
  end

  describe "#build_fields_list/1" do
    test "It will convert the comma-separated strings" do
      input = [user: "name,id,location", comment: "type"]
      result = Utils.build_fields_list(input)

      assert result == [user: [:name, :id, :location], comment: [:type]]
    end

    test "It will filter out strings that cannot safely become atoms" do
      input = [user: "name,id,thisisneveranatom,location", comment: "type"]
      result = Utils.build_fields_list(input)

      assert result == [user: [:name, :id, :location], comment: [:type]]
    end

    test "It will handle other unexpected input" do
      input = [user: "name,id", comment: 10]
      result = Utils.build_fields_list(input)

      assert result == [user: [:name, :id], comment: []]
    end
  end
end
