require "test_helper"

class ConfigVagrantTest < Test::Unit::TestCase
  setup do
    @config = Vagrant::Config::VagrantConfig.new
  end

  should "return nil if home is nil" do
    File.expects(:expand_path).never
    assert @config.home.nil?
  end

  should "expand the path if home is not nil" do
    @config.home = "foo"
    File.expects(:expand_path).with("foo").once.returns("result")
    assert_equal "result", @config.home
  end
end
