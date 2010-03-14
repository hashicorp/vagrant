require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ActiveListTest < Test::Unit::TestCase
  setup do
    mock_config
  end

  context "class methods" do
    context "loading" do
      should "load if reload is given" do
        File.stubs(:file?).returns(true)
        File.expects(:open).once
        Vagrant::ActiveList.list(true)
      end

      should "not load if the active json file doesn't exist" do
        File.expects(:file?).with(Vagrant::ActiveList.path).returns(false)
        File.expects(:open).never
        assert_equal [], Vagrant::ActiveList.list(true)
      end

      should "parse the JSON by reading the file" do
        file = mock("file")
        data = mock("data")
        result = mock("result")
        File.expects(:file?).returns(true)
        File.expects(:open).with(Vagrant::ActiveList.path, 'r').once.yields(file)
        file.expects(:read).returns(data)
        JSON.expects(:parse).with(data).returns(result)
        assert_equal result, Vagrant::ActiveList.list(true)
      end

      should "not load if reload flag is false and already loaded" do
        File.expects(:file?).once.returns(false)
        result = Vagrant::ActiveList.list(true)
        assert result.equal?(Vagrant::ActiveList.list)
        assert result.equal?(Vagrant::ActiveList.list)
        assert result.equal?(Vagrant::ActiveList.list)
      end
    end

    context "vms" do
      setup do
        @list = ["foo", "bar"]
        Vagrant::ActiveList.stubs(:list).returns(@list)
      end

      should "return the list, but with each value as a VM" do
        new_seq = sequence("new")
        results = []
        @list.each do |item|
          result = mock("result-#{item}")
          Vagrant::VM.expects(:find).with(item).returns(result).in_sequence(new_seq)
          results << result
        end

        assert_equal results, Vagrant::ActiveList.vms
      end
    end

    context "path" do
      setup do
        Vagrant::Env.stubs(:home_path).returns("foo")
      end

      should "return the active file within the home path" do
        assert_equal File.join(Vagrant::Env.home_path, Vagrant::ActiveList::FILENAME), Vagrant::ActiveList.path
      end
    end
  end
end
