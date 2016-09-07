require 'test_helper'

class Partitionable::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Partitionable
  end
end
