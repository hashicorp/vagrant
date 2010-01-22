require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ConfigTest < Test::Unit::TestCase

  context "Hobo configuration" do
    test "a hash source is converted to dot methods"  do
      Hobo.config_from_hash!(:a => {:b => 1})
      assert_equal Hobo.config.a.b, 1
    end
  end
end
