require File.join(File.dirname(__FILE__), '..', 'test_helper')

class BoxTest < Test::Unit::TestCase
  context "class methods" do
    context "adding" do
      setup do
        @name = "foo"
        @uri = "bar"
      end

      should "create a new instance, set the variables, and add it" do
        box = mock("box")
        box.expects(:name=).with(@name)
        box.expects(:uri=).with(@uri)
        box.expects(:add).once
        Vagrant::Box.expects(:new).returns(box)
        Vagrant::Box.add(@name, @uri)
      end
    end
  end

  context "instance methods" do
    setup do
      @box = Vagrant::Box.new
    end

    should "execute the Add action when add is called" do
      @box.expects(:execute!).with(Vagrant::Actions::Box::Add).once
      @box.add
    end
  end
end
