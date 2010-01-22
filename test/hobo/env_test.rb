require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase

  context "Hobo environment handler" do
    setup do
      @handler = Hobo::Env.new
      @ensure = Hobo::Env::ENSURE
    end
    
    test "should not create any directories if they exist"  do
      File.expects(:exists?).times(@ensure[:dirs].length).returns(true)
      Dir.expects(:mkdir).never
      @handler.ensure_directories
    end

    test "should not copy any files if they exist" do
      File.expects(:exists?).times(@ensure[:files].length).returns(true)
      File.expects(:copy).never
      @handler.ensure_files
    end

    test "should load configuration" do
      dir_expectations
      file_expectations
      @handler.load_config do |file|
        assert_equal file, Hobo::Env::CONFIG.keys.first
        { :setting => 1 }
      end

      assert_equal Hobo.config.setting, 1
    end
  end

  def dir_expectations
    File.expects(:exists?).times(@ensure[:dirs].length).returns(false)
    Dir.expects(:mkdir).times(@ensure[:dirs].length).returns nil
  end

  def file_expectations
    File.expects(:exists?).times(@ensure[:files].length).returns(false)
    File.expects(:copy).times(@ensure[:files].length)
  end
end
