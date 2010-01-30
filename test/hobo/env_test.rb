require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase
  context "Hobo environment handler" do
    setup do
      @handler = Hobo::Env
      @ensure = Hobo::Env::ENSURE
      Hobo.config! nil
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
    
    test "should create the ensured directories if they don't exist" do
      file_seq = sequence("file_seq")
      
      @ensure[:dirs].each do |dir|
        File.expects(:exists?).returns(false).in_sequence(file_seq)
        Dir.expects(:mkdir).with(dir).in_sequence(file_seq)
      end
      
      @handler.ensure_directories
    end
    
    test "should create the ensured files if they don't exist" do
      file_seq = sequence("file_seq")
      
      @ensure[:files].each do |target, default|
        File.expects(:exists?).with(target).returns(false).in_sequence(file_seq)
        File.expects(:copy).with(File.join(PROJECT_ROOT, default), target).in_sequence(file_seq)
      end
      
      @handler.ensure_files
    end

    test "should load of the default" do
      config_file_expectation
      @handler.load_config!
      assert_equal Hobo.config[:ssh], hobo_mock_config[:ssh]                                    
    end

    test "Hobo.config should be nil unless loaded" do
      assert_equal Hobo.config, nil
    end

    test "loading of the uuid from the dotfile" do
      dot_file_expectation
      Hobo.config! hobo_mock_config
      Hobo::Env.load_uuid!
      assert_equal Hobo::Env.persisted_uuid, 'foo'
    end

    test "load! should load the config and set the persisted_uid" do
      dot_file_expectation
      config_file_expectation
      Hobo::Env.load!
    end
    
    def dot_file_expectation
      File.expects(:open).with('.hobo', 'r').returns(['foo'])
    end

    def config_file_expectation
      YAML.expects(:load_file).with(Hobo::Env::CONFIG.keys.first).returns(hobo_mock_config)
    end
  end
end
