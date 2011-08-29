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
    assert_equal key, @instance.errors.first
  end
end
