require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class UnpackageActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Unpackage)
    @expanded_path =  File.join(FileUtils.pwd, 'foo.box')
    File.stubs(:expand_path).returns(@expanded_path)
    @action.package_file_path = 'foo.box'
    mock_config
  end

  # TODO test actual decompression
  should "call decompress with the path to the file and the directory to decompress to" do
    new_base_dir = File.join Vagrant.config[:vagrant][:home], 'foo'
    FileUtils.expects(:mv).with(@action.working_dir, new_base_dir).once
    Dir.expects(:[]).returns(File.join new_base_dir, 'something.ovf')
    @action.expects(:decompress)
    @action.execute!
  end

  should "return the full package file path without extension for the working directory" do
    assert_equal @action.working_dir, @action.package_file_path.gsub(/\.box/, '')
  end

  should "return base name without extension" do
    assert_equal @action.file_name_without_extension, 'foo'
  end

  should "call decompress with the defined options and the correct package path" do
    Tar.expects(:open).with(@expanded_path, *Vagrant::Actions::VM::Unpackage::TAR_OPTIONS)
    @action.decompress
  end

  should "return a new base dir under the home dir with the same name as the file without the extension" do
    assert_equal @action.new_base_dir, File.join(Vagrant.config.vagrant.home, 'foo')
  end
end
