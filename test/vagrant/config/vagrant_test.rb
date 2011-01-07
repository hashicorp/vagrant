require "test_helper"

class ConfigVagrantTest < Test::Unit::TestCase
  setup do
    @config = Vagrant::Config::VagrantConfig.new
  end

  context "validation" do
    setup do
      @config.dotfile_name = "foo"
      @config.host = "foo"

      @errors = Vagrant::Config::ErrorRecorder.new
    end

    should "be valid with given set of values" do
      @config.validate(@errors)
      assert @errors.errors.empty?
    end

    should "be invalid with no dotfile" do
      @config.dotfile_name = nil

      @config.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be invalid with no host" do
      @config.host = nil

      @config.validate(@errors)
      assert !@errors.errors.empty?
    end
  end
end
