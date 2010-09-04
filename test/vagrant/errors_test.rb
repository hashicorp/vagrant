require "test_helper"

class ErrorsTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Errors::VagrantError
    @super = Class.new(@klass) { error_namespace("vagrant.test.errors") }
  end

  should "set the given status code" do
    klass = Class.new(@super) { status_code(4444) }
    assert_equal 4444, klass.new.status_code
  end

  should "raise an error if attempting to set the same status code twice" do
    klass = Class.new(@super) { status_code(4445) }

    assert_raises(RuntimeError) {
      Class.new(@super) { status_code(4445) }
    }
  end

  should "translate the given message if non-hash is given" do
    klass = Class.new(@super)
    assert_equal I18n.t("vagrant.test.errors.test_key"), klass.new("test_key").message
  end

  should "use the alternate namespace if given" do
    klass = Class.new(@super)
    instance = klass.new(:_key => :test_key, :_namespace => "vagrant.test.alternate")
    assert_equal I18n.t("vagrant.test.alternate.test_key"), instance.message
  end

  should "use the translation from I18n if specified" do
    klass = Class.new(@super) { error_key(:test_key) }
    assert_equal I18n.t("vagrant.test.errors.test_key"), klass.new.message
  end

  should "use the translation with the options specified if key given" do
    klass = Class.new(@super) { error_key(:test_key_with_interpolation) }
    assert_equal I18n.t("vagrant.test.errors.test_key_with_interpolation", :key => "yo"), klass.new(:key => "yo").message
  end
end
