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

    test "should load configuration" do
      @handler.expects(:ensure_directories).once
      @handler.expects(:ensure_files).once
      @handler.load_config do |file|
        assert_equal file, Hobo::Env::CONFIG.keys.first
        { :setting => 1 }
      end

      assert_equal Hobo.config[:setting], 1
    end
  end
end
