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
        assert_equal file, Hobo::Env::CONFIG_FILE.keys.first
        { :setting => 1 }
      end
      assert_equal Hobo::Config.config.setting,  1
    end
  end

  #TODO Expectations will fail if .hobo dir is present
  def dir_expectations
    Dir.expects(:mkdir).times(Hobo::Env::DIRS.length).returns nil
  end

  def file_expectations
    File.expects(:copy).times(Hobo::Env::FILES.length)
  end
end
