require "test_helper"

class ErrorsTest < Test::Unit::TestCase
  setup do
    @super = Vagrant::Errors::VagrantError
  end

  should "set the given status code" do
    klass = Class.new(@super) { status_code(4) }
    assert_equal 4, klass.new.status_code
  end

  should "use the given message if no set error key" do
    klass = Class.new(@super)
    assert_equal "foo", klass.new("foo").message
  end

  should "use the translation from I18n if specified" do
    klass = Class.new(@super) { error_key(:test_key) }
    assert_equal I18n.t("vagrant.errors.test_key"), klass.new.message
  end

  should "use the translation with the options specified if key given" do
    klass = Class.new(@super) { error_key(:test_key_with_interpolation) }
    assert_equal I18n.t("vagrant.errors.test_key_with_interpolation", :key => "yo"), klass.new(:key => "yo").message
  end
end
