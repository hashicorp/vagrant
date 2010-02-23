require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class BaseActionTest < Test::Unit::TestCase
  should "include the util class so subclasses have access to it" do
    assert Vagrant::Actions::Base.include?(Vagrant::Util)
  end

  context "base instance" do
    setup do
      @mock_vm = mock("vm")
      @base = Vagrant::Actions::Base.new(@mock_vm)
    end

    should "allow read-only access to the runner" do
      assert_equal @mock_vm, @base.runner
    end

    should "implement prepare which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:prepare)
        @base.prepare
      end
    end

    should "implement the execute! method which does nothing" do
      assert_nothing_raised do
        assert @base.respond_to?(:execute!)
        @base.execute!
      end
    end
  end
end
