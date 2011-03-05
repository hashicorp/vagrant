require "test_helper"

class BoxTest < Test::Unit::TestCase
  context "class methods" do
    setup do
      @env = vagrant_env
    end

    context "adding" do
      setup do
        @name = "foo"
        @uri = "bar"
      end

      should "create a new instance, set the variables, and add it" do
        box = mock("box")
        box.expects(:uri=).with(@uri)
        box.expects(:add).once
        Vagrant::Box.expects(:new).with(@env, @name).returns(box)
        Vagrant::Box.add(@env, @name, @uri)
      end
    end
  end

  context "instance methods" do
    setup do
      @box = Vagrant::Box.new(vagrant_env, "foo")
    end

    should "raise an exception if a box exists with the name we're attempting to add" do
      vagrant_box(@box.name)

      assert_raises(Vagrant::Errors::BoxAlreadyExists) {
        @box.add
      }
    end

    should "execute the Add action when add is called" do
      @box.env.actions.expects(:run).with(:box_add, { "box" => @box, "validate" => false })
      @box.add
    end

    context "box directory" do
      should "return the boxes_path joined with the name" do
        assert_equal @box.env.boxes_path.join(@box.name), @box.directory
      end
    end

    context "destroying" do
      should "execute the destroy action" do
        @box.env.actions.expects(:run).with(:box_remove, { "box" => @box, "validate" => false })
        @box.destroy
      end
    end

    context "repackaging" do
      should "execute the repackage action" do
        @box.env.actions.expects(:run).with(:box_repackage, { "box" => @box, "validate" => false })
        @box.repackage
      end

      should "forward given options into the action" do
        @box.env.actions.expects(:run).with(:box_repackage, { "box" => @box, "foo" => "bar", "validate" => false })
        @box.repackage("foo" => "bar")
      end
    end

    context "ovf file" do
      should "be the directory joined with the config ovf file" do
        assert_equal @box.directory.join(@box.env.config.vm.box_ovf), @box.ovf_file
      end
    end
  end
end
