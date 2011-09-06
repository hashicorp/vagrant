require "test_helper"

class CommandPackageCommandTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Command::PackageCommand
    @env = vagrant_env
  end

  def command(args, opts, env)
    @klass.new(args, opts, { :env => env })
  end

  context "initialization" do
    should "require an environment" do
      assert_raises(Vagrant::Errors::CLIMissingEnvironment) { command([], {}, nil) }
      assert_nothing_raised { command([], {}, @env) }
    end
  end

  should "raise an exception if VM for supplied base option is not found" do
    Vagrant::VM.stubs(:find).returns(Vagrant::VM.new(nil))

    assert_raises(Vagrant::Errors::BaseVMNotFound) {
      command([], { :base => "foo" }, @env).execute
    }
  end
end
