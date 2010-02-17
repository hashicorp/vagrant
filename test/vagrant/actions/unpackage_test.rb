require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class UnpackageActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::Unpackage)
    mock_config
  end  

  # TODO test actual decompression
  should "call decompress with the path to the file and the directory to decompress to" do
    new_base_dir = File.join Vagrant.config[:vagrant][:home], 'something'
    file = File.join(FileUtils.pwd, 'something.box')
    FileUtils.expects(:mkpath).with(new_base_dir).once
    Dir.expects(:[]).returns(File.join new_base_dir, 'something.ovf')
    @action.expects(:decompress_to).with(new_base_dir).once
    @action.stubs(:package_file_path).returns(file)
    @action.execute!
  end
end
