require File.join(File.dirname(__FILE__), '..', 'test_helper')

class BoxTest < Test::Unit::TestCase
  context "class methods" do
    context "finding" do
      setup do
        @dir = "foo"
        @name = "bar"
        Vagrant::Box.stubs(:directory).with(@name).returns(@dir)
      end

      should "return nil if the box doesn't exist" do
        File.expects(:directory?).with(@dir).once.returns(false)
        assert_nil Vagrant::Box.find(@name)
      end

      should "return a box object with the proper name set" do
        File.expects(:directory?).with(@dir).once.returns(true)
        result = Vagrant::Box.find(@name)
        assert result
        assert_equal @name, result.name
      end
    end

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

    context "box directory" do
      setup do
        @name = "foo"
        @box_dir = File.join(Vagrant::Env.boxes_path, @name)
      end

      should "return the boxes_path joined with the name" do
        assert_equal @box_dir, Vagrant::Box.directory(@name)
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

    context "box directory" do
      setup do
        @box.name = "foo"
      end

      should "return the boxes_path joined with the name" do
        result = mock("object")
        Vagrant::Box.expects(:directory).with(@box.name).returns(result)
        assert result.equal?(@box.directory)
      end
    end

    context "destroying" do
      setup do
        @dir = mock("directory")
        @box.stubs(:directory).returns(@dir)
      end

      should "rm_rf the directory" do
        FileUtils.expects(:rm_rf).with(@dir).once
        @box.destroy
      end
    end
  end
end
