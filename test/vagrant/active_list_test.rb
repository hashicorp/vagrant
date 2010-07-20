require "test_helper"

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
      assert_equal Hash.new, @list.list(true)
    end

    should "parse the JSON by reading the file" do
      file = mock("file")
      data = mock("data")
      result = { :hey => :yep }
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

    should "be an empty hash if JSON parsing raises an exception" do
      file = mock("file")
      file.stubs(:read)
      File.expects(:file?).returns(true)
      File.expects(:open).with(@list.path, 'r').once.yields(file)
      JSON.expects(:parse).raises(Exception)

      assert_nothing_raised do
        assert_equal Hash.new, @list.list(true)
      end
    end
  end

  context "filter list" do
    should "remove nonexistent VMs" do
      list = {}
      result = {}
      5.times do |i|
        vm = mock("vm#{i}")
        vm.stubs(:uuid).returns(i)

        list[vm.uuid] = {}

        found_vm = i % 2 ? nil : vm
        Vagrant::VM.stubs(:find).with(vm.uuid, @env).returns(found_vm)
        results[vm.uuid] = {} if found_vm
      end

      @list.stubs(:list).returns(list)
      assert_equal result, @list.filter_list
    end
  end

  context "adding a VM to the list" do
    setup do
      @the_list = {}
      @list.stubs(:list).returns(@the_list)
      @list.stubs(:save)

      @uuid = "foo"
      @vm = mock("vm")
      @vm.stubs(:uuid).returns(@uuid)
    end

    should "add the VMs UUID to the list" do
      @list.add(@vm)
      assert @the_list[@uuid]
      assert @the_list[@uuid].is_a?(Hash)
    end

    should "save after adding" do
      save_seq = sequence('save')
      @the_list.expects(:[]=).in_sequence(save_seq)
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
      @list.stubs(:filter_list).returns(@filtered)
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
