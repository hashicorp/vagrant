require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::Plugin do
  before do
    allow(described_class).to receive(:manager)
      .and_return(Vagrant::Plugin::V2::Manager.new)
  end

  it "should be able to set and get the name" do
    plugin = Class.new(described_class) do
      name "foo"
    end

    expect(plugin.name).to eq("foo")
  end

  it "should be able to set and get the description" do
    plugin = Class.new(described_class) do
      description "bar"
    end

    expect(plugin.description).to eq("bar")
  end

  describe "action hooks" do
    it "should register on all actions by default" do
      plugin = Class.new(described_class) do
        action_hook("foo") { "bar" }
      end

      hooks_registry = plugin.components.action_hooks
      hooks = hooks_registry[described_class.const_get("ALL_ACTIONS")]
      expect(hooks.length).to eq(1)
      expect(hooks[0].call).to eq("bar")
    end

    it "should register for a specific action by default" do
      plugin = Class.new(described_class) do
        action_hook("foo", :bar) { "bar" }
      end

      hooks_registry = plugin.components.action_hooks
      hooks = hooks_registry[:bar]
      expect(hooks.length).to eq(1)
      expect(hooks[0].call).to eq("bar")
    end
  end

  describe "commands" do
    it "should register command classes" do
      plugin = Class.new(described_class) do
        command("foo") { "bar" }
      end

      expect(plugin.components.commands.keys).to be_include(:foo)
      expect(plugin.components.commands[:foo][0].call).to eql("bar")
    end

    it "should register command classes with options" do
      plugin = Class.new(described_class) do
        command("foo", opt: :bar) { "bar" }
      end

      expect(plugin.components.commands.keys).to be_include(:foo)
      expect(plugin.components.commands[:foo][0].call).to eql("bar")
      expect(plugin.components.commands[:foo][1][:opt]).to eql(:bar)
    end

    it "should register commands as primary by default" do
      plugin = Class.new(described_class) do
        command("foo") { "bar" }
        command("bar", primary: false) { "bar" }
      end

      expect(plugin.components.commands[:foo][1][:primary]).to be(true)
      expect(plugin.components.commands[:bar][1][:primary]).to be(false)
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
        plugin.components.commands[:foo][0].call
      }.to raise_error(StandardError, "FAIL!")
    end
  end

  describe "communicators" do
    it "should register communicator classes" do
      plugin = Class.new(described_class) do
        communicator("foo") { "bar" }
      end

      expect(plugin.communicator[:foo]).to eq("bar")
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

      expect(plugin.components.configs[:top][:foo]).to eq("bar")
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

      expect(plugin.components.configs[:provider][:foo]).to eq("bar")
    end
  end

  describe "guests" do
    it "should register guest classes" do
      plugin = Class.new(described_class) do
        guest("foo") { "bar" }
      end

      expect(plugin.components.guests[:foo]).to eq(["bar", nil])
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

      expect(plugin.components.guest_capabilities[:foo][:bar]).to eq("baz")
    end
  end

  describe "hosts" do
    it "should register host classes" do
      plugin = Class.new(described_class) do
        host("foo") { "bar" }
      end

      expect(plugin.components.hosts[:foo]).to eq(["bar", nil])
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

  describe "host capabilities" do
    it "should register host capabilities" do
      plugin = Class.new(described_class) do
        host_capability("foo", "bar") { "baz" }
      end

      expect(plugin.components.host_capabilities[:foo][:bar]).to eq("baz")
    end
  end

  describe "providers" do
    it "should register provider classes" do
      plugin = Class.new(described_class) do
        provider("foo") { "bar" }
      end

      result = plugin.components.providers[:foo]
      expect(result[0]).to eq("bar")
      expect(result[1][:priority]).to eq(5)
    end

    it "should register provider classes with options" do
      plugin = Class.new(described_class) do
        provider("foo", foo: "yep") { "bar" }
      end

      result = plugin.components.providers[:foo]
      expect(result[0]).to eq("bar")
      expect(result[1][:priority]).to eq(5)
      expect(result[1][:foo]).to eq("yep")
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

  describe "provider capabilities" do
    it "should register host capabilities" do
      plugin = Class.new(described_class) do
        provider_capability("foo", "bar") { "baz" }
      end

      expect(plugin.components.provider_capabilities[:foo][:bar]).to eq("baz")
    end
  end

  describe "provisioners" do
    it "should register provisioner classes" do
      plugin = Class.new(described_class) do
        provisioner("foo") { "bar" }
      end

      expect(plugin.provisioner[:foo]).to eq("bar")
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

  describe "pushes" do
    it "should register implementations" do
      plugin = Class.new(described_class) do
        push("foo") { "bar" }
      end

      expect(plugin.components.pushes[:foo]).to eq(["bar", nil])
    end

    it "should be able to specify priorities" do
      plugin = Class.new(described_class) do
        push("foo", bar: 1) { "bar" }
      end

      expect(plugin.components.pushes[:foo]).to eq(["bar", bar: 1])
    end

    it "should lazily register implementations" do
      # Below would raise an error if the value of the config class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
          push("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the configuration key that
      # a proper error is raised.
      expect {
        plugin.components.pushes[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "synced folders" do
    it "should register implementations" do
      plugin = Class.new(described_class) do
        synced_folder("foo") { "bar" }
      end

      expect(plugin.components.synced_folders[:foo]).to eq(["bar", 10])
    end

    it "should be able to specify priorities" do
      plugin = Class.new(described_class) do
        synced_folder("foo", 50) { "bar" }
      end

      expect(plugin.components.synced_folders[:foo]).to eq(["bar", 50])
    end

    it "should lazily register implementations" do
      # Below would raise an error if the value of the config class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
          synced_folder("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the configuration key that
      # a proper error is raised.
      expect {
        plugin.components.synced_folders[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "plugin registration" do
    let(:manager) { described_class.manager }

    it "should have no registered plugins" do
      expect(manager.registered).to be_empty
    end

    it "should register a plugin when a name is set" do
      plugin = Class.new(described_class) do
        name "foo"
      end

      expect(manager.registered).to eq([plugin])
    end

    it "should register a plugin only once" do
      plugin = Class.new(described_class) do
        name "foo"
        name "bar"
      end

      expect(manager.registered).to eq([plugin])
    end
  end
end
