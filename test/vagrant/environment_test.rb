require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase
  setup do
    mock_config
  end

  context "loading config" do
    setup do
      @root_path = "/foo"
      @env = Vagrant::Environment.new
      @env.stubs(:root_path).returns(@root_path)

      File.stubs(:exist?).returns(false)
      Vagrant::Config.stubs(:execute!)
      Vagrant::Config.stubs(:reset!)
    end

    should "reset the configuration object" do
      Vagrant::Config.expects(:reset!).once
      @env.load_config!
    end

    should "load from the project root" do
      File.expects(:exist?).with(File.join(PROJECT_ROOT, "config", "default.rb")).once
      @env.load_config!
    end

    should "load from the root path" do
      File.expects(:exist?).with(File.join(@root_path, Vagrant::Environment::ROOTFILE_NAME)).once
      @env.load_config!
    end

    should "not load from the root path if nil" do
      @env.stubs(:root_path).returns(nil)
      File.expects(:exist?).with(File.join(@root_path, Vagrant::Environment::ROOTFILE_NAME)).never
      @env.load_config!
    end

    should "load the files only if exist? returns true" do
      File.expects(:exist?).once.returns(true)
      @env.expects(:load).once
      @env.load_config!
    end

    should "not load the files if exist? returns false" do
      @env.expects(:load).never
      @env.load_config!
    end

    should "execute after loading and set result to environment config" do
      result = mock("result")
      File.expects(:exist?).once.returns(true)
      @env.expects(:load).once
      Vagrant::Config.expects(:execute!).once.returns(result)
      @env.load_config!
      assert_equal result, @env.config
    end
  end
end
