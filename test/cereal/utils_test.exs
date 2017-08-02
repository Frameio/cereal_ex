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
      includes = "account,user,subscriptions"
      expected = [user: [], account: []]

      assert Utils.normalize_includes(includes) == expected
    end

    test "will normalize a deep include" do
      includes = "account,account.user,account.user.parent"
      expected = [account: [user: [parent: []]]]

      assert Utils.normalize_includes(includes) == expected
    end
  end
end
