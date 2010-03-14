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

      should "compact out the nil values" do
        Vagrant::VM.stubs(:find).returns(nil)
        results = Vagrant::ActiveList.vms
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

        Vagrant::ActiveList.stubs(:vms).returns(vms)
        assert_equal result, Vagrant::ActiveList.filtered_list
      end
    end

    context "adding a VM to the list" do
      setup do
        @list = []
        Vagrant::ActiveList.stubs(:list).returns(@list)
        Vagrant::ActiveList.stubs(:save)

        @uuid = "foo"
        @vm = mock("vm")
        @vm.stubs(:uuid).returns(@uuid)
      end

      should "add the VMs UUID to the list" do
        Vagrant::ActiveList.add(@vm)
        assert_equal [@uuid], @list
      end

      should "uniq the array so multiples never exist" do
        @list << @uuid
        assert_equal 1, @list.length
        Vagrant::ActiveList.add(@vm)
        assert_equal 1, @list.length
      end

      should "save after adding" do
        save_seq = sequence('save')
        @list.expects(:<<).in_sequence(save_seq)
        Vagrant::ActiveList.expects(:save).in_sequence(save_seq)
        Vagrant::ActiveList.add(@vm)
      end
    end

    context "deleting a VM from the list" do
      setup do
        @list = ["bar"]
        Vagrant::ActiveList.stubs(:list).returns(@list)
        Vagrant::ActiveList.stubs(:save)

        @uuid = "bar"
        @vm = mock("vm")
        @vm.stubs(:uuid).returns(@uuid)
        @vm.stubs(:is_a?).with(Vagrant::VM).returns(true)
      end

      should "delete the uuid from the list of a VM" do
        Vagrant::ActiveList.remove(@vm)
        assert @list.empty?
      end

      should "delete just the string if a string is given" do
        @list << "zoo"
        Vagrant::ActiveList.remove("zoo")
        assert !@list.include?("zoo")
      end

      should "save after removing" do
        save_seq = sequence('save')
        @list.expects(:delete).in_sequence(save_seq)
        Vagrant::ActiveList.expects(:save).in_sequence(save_seq)
        Vagrant::ActiveList.remove(@vm)
      end
    end

    context "saving" do
      setup do
        @filtered = ["zoo"]
        Vagrant::ActiveList.stubs(:filtered_list).returns(@filtered)
      end

      should "open the JSON path and save to it" do
        file = mock("file")
        File.expects(:open).with(Vagrant::ActiveList.path, "w+").yields(file)
        file.expects(:write).with(@filtered.to_json)
        Vagrant::ActiveList.save
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
