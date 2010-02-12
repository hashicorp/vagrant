require File.join(File.dirname(__FILE__), '..', 'test_helper')

class BoxedTest< Test::Unit::TestCase
  context "exporting a vm" do
    should "create a tar in the specified directory" do
      vm = mock('vm')
      location = '/Users/johnbender/Desktop'
      name = 'my_box'
      new_dir = File.join(location, name)
      vm.expects(:export).with(File.join(new_dir, "#{name}.ovf"))
      FileUtils.expects(:mkpath).with(new_dir).returns(new_dir)
      Tar.expects(:open)

      # TODO test whats passed to the open tar.append_tree
      assert_equal Vagrant::Packaged.new(name, :vm => vm).compress(location), "#{new_dir}.tar"
    end
  end
end
