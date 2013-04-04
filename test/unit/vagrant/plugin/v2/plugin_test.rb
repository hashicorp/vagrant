require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::Plugin do
  after(:each) do
    # We want to make sure that the registered plugins remains empty
    # after each test.
    described_class.manager.reset!
  end

  it "should be able to set and get the name" do
    plugin = Class.new(described_class) do
      name "foo"
    end

    plugin.name.should == "foo"
  end

  it "should be able to set and get the description" do
    plugin = Class.new(described_class) do
      description "bar"
    end

    plugin.description.should == "bar"
  end

  describe "action hooks" do
    it "should register on all actions by default" do
      plugin = Class.new(described_class) do
        action_hook("foo") { "bar" }
      end

      hooks_registry = plugin.components.action_hooks
      hooks = hooks_registry[described_class.const_get("ALL_ACTIONS")]
      hooks.length.should == 1
      hooks[0].call.should == "bar"
    end

    it "should register for a specific action by default" do
      plugin = Class.new(described_class) do
        action_hook("foo", :bar) { "bar" }
      end

      hooks_registry = plugin.components.action_hooks
      hooks = hooks_registry[:bar]
      hooks.length.should == 1
      hooks[0].call.should == "bar"
    end
  end

  describe "commands" do
    it "should register command classes" do
      plugin = Class.new(described_class) do
        command("foo") { "bar" }
      end

      plugin.command[:foo].should == "bar"
    end

    ["spaces bad", "sym^bols"].each do |bad|
      it "should not allow bad command name: #{bad}" do
        plugin = Class.new(described_class)

        expect { plugin.command(bad) {} }.
          to raise_error(Vagrant::Plugin::V2::InvalidCommandName)
      end
    end

    it "should lazily register command classes" do
      # Below would raise an error if the value of the command class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
        command("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the command key that
      # a proper error is raised.
      expect {
        plugin.command[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "communicators" do
    it "should register communicator classes" do
      plugin = Class.new(described_class) do
        communicator("foo") { "bar" }
      end

      plugin.communicator[:foo].should == "bar"
    end

    it "should lazily register communicator classes" do
      # Below would raise an error if the value of the class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
        communicator("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the configuration key that
      # a proper error is raised.
      expect {
        plugin.communicator[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "configuration" do
    it "should register configuration classes" do
      plugin = Class.new(described_class) do
        config("foo") { "bar" }
      end

      plugin.components.configs[:top][:foo].should == "bar"
    end

    it "should lazily register configuration classes" do
      # Below would raise an error if the value of the config class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
        config("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the configuration key that
      # a proper error is raised.
      expect {
        plugin.components.configs[:top][:foo]
      }.to raise_error(StandardError)
    end

    it "should register configuration classes for providers" do
      plugin = Class.new(described_class) do
        config("foo", :provider) { "bar" }
      end

      plugin.components.configs[:provider][:foo].should == "bar"
    end
  end

  describe "guests" do
    it "should register guest classes" do
      plugin = Class.new(described_class) do
        guest("foo") { "bar" }
      end

      plugin.components.guests[:foo].should == ["bar", nil]
    end

    it "should lazily register guest classes" do
      # Below would raise an error if the value of the guest class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
          guest("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the guest key that
      # a proper error is raised.
      expect {
        plugin.guest[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "guest capabilities" do
    it "should register guest capabilities" do
      plugin = Class.new(described_class) do
        guest_capability("foo", "bar") { "baz" }
      end

      plugin.components.guest_capabilities[:foo][:bar].should == "baz"
    end
  end

  describe "hosts" do
    it "should register host classes" do
      plugin = Class.new(described_class) do
        host("foo") { "bar" }
      end

      plugin.host[:foo].should == "bar"
    end

    it "should lazily register host classes" do
      # Below would raise an error if the value of the host class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
          host("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the host key that
      # a proper error is raised.
      expect {
        plugin.host[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "providers" do
    it "should register provider classes" do
      plugin = Class.new(described_class) do
        provider("foo") { "bar" }
      end

      plugin.components.providers[:foo].should == ["bar", {}]
    end

    it "should register provider classes with options" do
      plugin = Class.new(described_class) do
        provider("foo", foo: "yep") { "bar" }
      end

      plugin.components.providers[:foo].should == ["bar", { foo: "yep" }]
    end

    it "should lazily register provider classes" do
      # Below would raise an error if the value of the config class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
          provider("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the configuration key that
      # a proper error is raised.
      expect {
        plugin.components.providers[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "provisioners" do
    it "should register provisioner classes" do
      plugin = Class.new(described_class) do
        provisioner("foo") { "bar" }
      end

      plugin.provisioner[:foo].should == "bar"
    end

    it "should lazily register provisioner classes" do
      # Below would raise an error if the value of the config class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
          provisioner("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the configuration key that
      # a proper error is raised.
      expect {
        plugin.provisioner[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "plugin registration" do
    let(:manager) { described_class.manager }

    it "should have no registered plugins" do
      manager.registered.should be_empty
    end

    it "should register a plugin when a name is set" do
      plugin = Class.new(described_class) do
        name "foo"
      end

      manager.registered.should == [plugin]
    end

    it "should register a plugin only once" do
      plugin = Class.new(described_class) do
        name "foo"
        name "bar"
      end

      manager.registered.should == [plugin]
    end
  end
end
