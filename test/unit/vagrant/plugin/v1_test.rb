require File.expand_path("../../../base", __FILE__)

describe Vagrant::Plugin::V1 do
  after(:each) do
    # We want to make sure that the registered plugins remains empty
    # after each test.
    described_class.registered.clear
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

  describe "configuration" do
    it "should register configuration classes" do
      plugin = Class.new(described_class) do
        config("foo") { "bar" }
      end

      plugin.config[:foo].should == "bar"
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
        plugin.config[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "guests" do
    it "should register guest classes" do
      plugin = Class.new(described_class) do
        guest("foo") { "bar" }
      end

      plugin.guest[:foo].should == "bar"
    end

    it "should lazily register configuration classes" do
      # Below would raise an error if the value of the config class was
      # evaluated immediately. By asserting that this does not raise an
      # error, we verify that the value is actually lazily loaded
      plugin = nil
      expect {
        plugin = Class.new(described_class) do
          guest("foo") { raise StandardError, "FAIL!" }
        end
      }.to_not raise_error

      # Now verify when we actually get the configuration key that
      # a proper error is raised.
      expect {
        plugin.guest[:foo]
      }.to raise_error(StandardError)
    end
  end

  describe "plugin registration" do
    it "should have no registered plugins" do
      described_class.registered.should be_empty
    end

    it "should register a plugin when a name is set" do
      plugin = Class.new(described_class) do
        name "foo"
      end

      described_class.registered.should == [plugin]
    end

    it "should register a plugin only once" do
      plugin = Class.new(described_class) do
        name "foo"
        name "bar"
      end

      described_class.registered.should == [plugin]
    end
  end
end
