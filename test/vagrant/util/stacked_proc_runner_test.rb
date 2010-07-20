require "test_helper"

class StackedProcRunnerUtilTest < Test::Unit::TestCase
  class TestClass
    include Vagrant::Util::StackedProcRunner
  end

  setup do
    @instance = TestClass.new
    @instance.proc_stack.clear
  end

  should "not run the procs right away" do
    obj = mock("obj")
    obj.expects(:foo).never
    @instance.push_proc { |config| obj.foo }
    @instance.push_proc { |config| obj.foo }
    @instance.push_proc { |config| obj.foo }
  end

  should "run the blocks when run_procs! is ran" do
    obj = mock("obj")
    obj.expects(:foo).times(2)
    @instance.push_proc { obj.foo }
    @instance.push_proc { obj.foo }
    @instance.run_procs!
  end

  should "run the blocks with the same arguments" do
    passed_config = mock("config")
    @instance.push_proc { |config| assert passed_config.equal?(config) }
    @instance.push_proc { |config| assert passed_config.equal?(config) }
    @instance.run_procs!(passed_config)
  end

  should "not clear the blocks after running" do
    obj = mock("obj")
    obj.expects(:foo).times(2)
    @instance.push_proc { obj.foo }
    @instance.run_procs!
    @instance.run_procs!
  end
end
