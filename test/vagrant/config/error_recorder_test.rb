require "test_helper"

class ConfigErrorsTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Config::ErrorRecorder
    @instance = @klass.new
  end

  should "not have any errors to start" do
    assert @instance.errors.empty?
  end

  should "add errors" do
    key = "vagrant.test.errors.test_key"
    @instance.add(key)
    assert_equal I18n.t(key), @instance.errors.first
  end

  should "interpolate error messages if options given" do
    key = "vagrant.test.errors.test_key_with_interpolation"
    @instance.add(key, :key => "hey")
    assert_equal I18n.t(key, :key => "hey"), @instance.errors.first
  end
end
