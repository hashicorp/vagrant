require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ActiveListTest < Test::Unit::TestCase
  setup do
    @env = mock_environment
    @list = Vagrant::ActiveList.new(@env)
  end

  context "initializing" do
    should "set the environment to nil if not specified" do
      assert_nothing_raised {
        list = Vagrant::ActiveList.new
        assert list.env.nil?
      }
    end

    should "set the environment to the given parameter if specified" do
      env = mock("env")
      list = Vagrant::ActiveList.new(env)
      assert_equal env, list.env
    end
  end

  context "listing" do
    setup do
      @path = "foo"
      @list.stubs(:path).returns(@path)
    end

    should "load if reload is given" do
      File.stubs(:file?).returns(true)
      File.expects(:open).once
      @list.list(true)
    end

    should "not load if the active json file doesn't exist" do
      File.expects(:file?).with(@list.path).returns(false)
      File.expects(:open).never
      assert_equal [], @list.list(true)
    end

    should "parse the JSON by reading the file" do
      file = mock("file")
      data = mock("data")
      result = mock("result")
      File.expects(:file?).returns(true)
      File.expects(:open).with(@list.path, 'r').once.yields(file)
      file.expects(:read).returns(data)
      JSON.expects(:parse).with(data).returns(result)
      assert_equal result, @list.list(true)
    end

    should "not load if reload flag is false and already loaded" do
      File.expects(:file?).once.returns(false)
      result = @list.list(true)
      assert result.equal?(@list.list)
      assert result.equal?(@list.list)
      assert result.equal?(@list.list)
    end
  end

  context "vms" do
    setup do
      @the_list = ["foo", "bar"]
      @list.stubs(:list).returns(@the_list)
    end

    should "return the list, but with each value as a VM" do
      new_seq = sequence("new")
      results = []
      @the_list.each do |item|
        result = mock("result-#{item}")
        Vagrant::VM.expects(:find).with(item).returns(result).in_sequence(new_seq)
        results << result
      end

      assert_equal results, @list.vms
    end

    should "compact out the nil values" do
      Vagrant::VM.stubs(:find).returns(nil)
      results = @list.vms
      assert results.empty?
    end
  end

  context "filtered list" do
    should "return a list of UUIDs from the VMs" do
      vms = []
      result = []
      5.times do |i|
        vm = mock("vm#{i}")
        vm.expects(:uuid).returns(i)
        result << i
        vms << vm
      end

      @list.stubs(:vms).returns(vms)
      assert_equal result, @list.filtered_list
    end
  end

  context "adding a VM to the list" do
    setup do
      @the_list = []
      @list.stubs(:list).returns(@the_list)
      @list.stubs(:save)

      @uuid = "foo"
      @vm = mock("vm")
      @vm.stubs(:uuid).returns(@uuid)
    end

    should "add the VMs UUID to the list" do
      @list.add(@vm)
      assert_equal [@uuid], @the_list
    end

    should "uniq the array so multiples never exist" do
      @the_list << @uuid
      assert_equal 1, @the_list.length
      @list.add(@vm)
      assert_equal 1, @the_list.length
    end

    should "save after adding" do
      save_seq = sequence('save')
      @the_list.expects(:<<).in_sequence(save_seq)
      @list.expects(:save).in_sequence(save_seq)
      @list.add(@vm)
    end
  end

  context "deleting a VM from the list" do
    setup do
      @the_list = ["bar"]
      @list.stubs(:list).returns(@the_list)
      @list.stubs(:save)

      @uuid = "bar"
      @vm = mock("vm")
      @vm.stubs(:uuid).returns(@uuid)
      @vm.stubs(:is_a?).with(Vagrant::VM).returns(true)
    end

    should "delete the uuid from the list of a VM" do
      @list.remove(@vm)
      assert @the_list.empty?
    end

    should "delete just the string if a string is given" do
      @the_list << "zoo"
      @list.remove("zoo")
      assert !@the_list.include?("zoo")
    end

    should "save after removing" do
      save_seq = sequence('save')
      @the_list.expects(:delete).in_sequence(save_seq)
      @list.expects(:save).in_sequence(save_seq)
      @list.remove(@vm)
    end
  end

  context "saving" do
    setup do
      @filtered = ["zoo"]
      @list.stubs(:filtered_list).returns(@filtered)
    end

    should "open the JSON path and save to it" do
      file = mock("file")
      File.expects(:open).with(@list.path, "w+").yields(file)
      file.expects(:write).with(@filtered.to_json)
      @list.save
    end
  end

  context "path" do
    setup do
      @env.stubs(:home_path).returns("foo")
    end

    should "return the active file within the home path" do
      assert_equal File.join(@env.home_path, Vagrant::ActiveList::FILENAME), @list.path
    end
  end
end
