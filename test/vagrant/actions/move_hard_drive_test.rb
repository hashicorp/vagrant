require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class MoveHardDriveActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::MoveHardDrive)
    @hd_location = "/foo"
    mock_config do |config|
      File.expects(:directory?).with(@hd_location).returns(true)
      config.vm.hd_location = @hd_location
    end
  end

  context "execution" do
    should "error and exit if the vm is not powered off" do
      @mock_vm.expects(:powered_off?).returns(false)
      @action.expects(:error_and_exit).once
      @action.execute!
    end

    should "move the hard drive if vm is powered off" do
      @mock_vm.expects(:powered_off?).returns(true)
      @action.expects(:error_and_exit).never
      @action.expects(:destroy_drive_after).once
      @action.execute!
    end
  end

  context "new image path" do
    setup do
      @hd = mock("hd")
      @image = mock("image")
      @filename = "foo"
      @hd.stubs(:image).returns(@image)
      @image.stubs(:filename).returns(@filename)
      @action.stubs(:hard_drive).returns(@hd)
    end

    should "be the configured hd location and the existing hard drive filename" do
      joined = File.join(Vagrant.config.vm.hd_location, @filename)
      assert_equal joined, @action.new_image_path
    end
  end

  context "cloning and attaching new image" do
    setup do
      @hd = mock("hd")
      @image = mock("image")
      @hd.stubs(:image).returns(@image)
      @action.stubs(:hard_drive).returns(@hd)
      @new_image_path = "foo"
      @action.stubs(:new_image_path).returns(@new_image_path)
    end

    should "clone to the new path" do
      new_image = mock("new_image")
      @image.expects(:clone).with(@new_image_path, Vagrant.config.vm.disk_image_format, true).returns(new_image).once
      @hd.expects(:image=).with(new_image).once
      @vm.expects(:save).once
      @action.clone_and_attach
    end
  end

  context "destroying the old image" do
    setup do
      @hd = mock("hd")
      @action.stubs(:hard_drive).returns(@hd)
    end

    should "yield the block, and destroy the old image after" do
      image = mock("image")
      image.stubs(:filename).returns("foo")
      destroy_seq = sequence("destroy_seq")
      @hd.expects(:image).returns(image).in_sequence(destroy_seq)
      @hd.expects(:foo).once.in_sequence(destroy_seq)
      image.expects(:destroy).with(true).once.in_sequence(destroy_seq)

      @action.destroy_drive_after { @hd.foo }
    end

    # Ensures that the image is not destroyed in an "ensure" block
    should "not destroy the image if an exception is raised" do
      image = mock("image")
      image.expects(:destroy).never
      @hd.expects(:image).returns(image)

      assert_raises(Exception) do
        @action.destroy_drive_after do
          raise Exception.new("FOO")
        end
      end
    end
  end
end
