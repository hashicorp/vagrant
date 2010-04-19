require File.join(File.dirname(__FILE__), '..', 'test_helper')

class BoxTest < Test::Unit::TestCase
  context "class methods" do
    setup do
      @env = mock_environment
    end

    context "listing all boxes" do
      setup do
        Dir.stubs(:open)
        File.stubs(:directory?).returns(true)

        @boxes_path = "foo"
        @env.stubs(:boxes_path).returns(@boxes_path)
      end

      should "open the boxes directory" do
        Dir.expects(:open).with(@env.boxes_path)
        Vagrant::Box.all(@env)
      end

      should "return an array" do
        result = Vagrant::Box.all(@env)
        assert result.is_a?(Array)
      end

      should "not return the '.' and '..' directories" do
        dir = [".", "..", "..", ".", ".."]
        Dir.expects(:open).yields(dir)
        result = Vagrant::Box.all(@env)
        assert result.empty?
      end

      should "return the other directories" do
        dir = [".", "foo", "bar", "baz"]
        Dir.expects(:open).yields(dir)
        result = Vagrant::Box.all(@env)
        assert_equal ["foo", "bar", "baz"], result
      end

      should "ignore the files" do
        dir = ["foo", "bar"]
        files = [true, false]
        Dir.expects(:open).yields(dir)
        dir_sequence = sequence("directory")
        dir.each_with_index do |dir, index|
          File.expects(:directory?).with(File.join(@boxes_path, dir)).returns(files[index]).in_sequence(dir_sequence)
        end

        result = Vagrant::Box.all(@env)
        assert_equal ["foo"], result
      end
    end

    context "finding" do
      setup do
        @dir = "foo"
        @name = "bar"
        Vagrant::Box.stubs(:directory).with(@env, @name).returns(@dir)
      end

      should "return nil if the box doesn't exist" do
        File.expects(:directory?).with(@dir).once.returns(false)
        assert_nil Vagrant::Box.find(@env, @name)
      end

      should "return a box object with the proper name set" do
        File.expects(:directory?).with(@dir).once.returns(true)
        result = Vagrant::Box.find(@env, @name)
        assert result
        assert_equal @name, result.name
      end

      should "return a box object with the proper env set" do
        File.expects(:directory?).with(@dir).once.returns(true)
        result = Vagrant::Box.find(@env, @name)
        assert result
        assert_equal @env, result.env
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
        box.expects(:env=).with(@env)
        box.expects(:add).once
        Vagrant::Box.expects(:new).returns(box)
        Vagrant::Box.add(@env, @name, @uri)
      end
    end

    context "box directory" do
      setup do
        @name = "foo"
        @box_dir = File.join(@env.boxes_path, @name)
      end

      should "return the boxes_path joined with the name" do
        assert_equal @box_dir, Vagrant::Box.directory(@env, @name)
      end
    end
  end

  context "instance methods" do
    setup do
      @box = Vagrant::Box.new
      @box.env = mock_environment
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
        Vagrant::Box.expects(:directory).with(@box.env, @box.name).returns(result)
        assert result.equal?(@box.directory)
      end
    end

    context "destroying" do
      should "execute the destroy action" do
        @box.expects(:execute!).with(Vagrant::Actions::Box::Destroy).once
        @box.destroy
      end
    end

    context "ovf file" do
      setup do
        @box.stubs(:directory).returns("foo")

        @box.env.config.vm.box_ovf = "foo.ovf"
      end

      should "be the directory joined with the config ovf file" do
        assert_equal File.join(@box.directory, @box.env.config.vm.box_ovf), @box.ovf_file
      end
    end
  end
end
