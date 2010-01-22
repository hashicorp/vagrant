require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase

  context "Hobo environment handler" do
    setup do
      @handler = Hobo::Env.new
    end
    
    test "should check for all required directories"  do
      dir_expectations
      @handler.ensure_directories
    end

    test "should check for all required config files" do
      file_expectations
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
    File.expects(:exists?).times(Hobo::Env::ENSURE[:dirs].length).returns(false)
    Dir.expects(:mkdir).times(Hobo::Env::ENSURE[:dirs].length).returns nil
  end

  def file_expectations
    File.expects(:exists?).times(Hobo::Env::ENSURE[:files].length).returns(false)
    File.expects(:copy).times(Hobo::Env::ENSURE[:files].length)
  end
end
