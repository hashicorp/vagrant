require File.expand_path("../../../base", __FILE__)

require "vagrant/registry"

describe Vagrant::Config::Loader do
  include_context "unit"

  # This is the current version of configuration for the tests.
  let(:current_version) { version_order.last }

  # This is just a dummy implementation of a configuraiton loader which
  # simply acts on hashes.
  let(:test_loader) do
    Class.new(Vagrant::Config::VersionBase) do
      def self.init
        {}
      end

      def self.load(proc)
        init.tap do |obj|
          proc.call(obj)
        end
      end

      def self.merge(old, new)
        old.merge(new)
      end
    end
  end

  let(:versions) do
    Vagrant::Registry.new.tap do |r|
      r.register("1") { test_loader }
    end
  end

  let(:version_order) { ["1"] }

  let(:instance) { described_class.new(versions, version_order) }

  describe "basic loading" do
    it "should ignore non-existent load order keys" do
      instance.load([:foo])
    end

    it "should load and return the configuration" do
      proc = Proc.new do |config|
        config[:foo] = "yep"
      end

      instance.set(:proc, [[current_version, proc]])
      config, warnings, errors = instance.load([:proc])

      expect(config[:foo]).to eq("yep")
      expect(warnings).to eq([])
      expect(errors).to eq([])
    end
  end

  describe "finalization" do
    it "should finalize the configuration" do
      # Create the finalize method on our loader
      def test_loader.finalize(obj)
        obj[:finalized] = true
        obj
      end

      # Basic configuration proc
      proc = lambda do |config|
        config[:foo] = "yep"
      end

      # Run the actual configuration and assert that we get the proper result
      instance.set(:proc, [[current_version, proc]])
      config, _ = instance.load([:proc])
      expect(config[:foo]).to eq("yep")
      expect(config[:finalized]).to eq(true)
    end
  end

  describe "upgrading" do
    it "should do an upgrade to the latest version" do
      test_loader_v2 = Class.new(test_loader) do
        def self.upgrade(old)
          new = old.dup
          new[:v2] = true

          [new, [], []]
        end
      end

      versions.register("2") { test_loader_v2 }
      version_order << "2"

      # Load a version 1 proc, and verify it is upgraded to version 2
      proc = lambda { |config| config[:foo] = "yep" }
      instance.set(:proc, [["1", proc]])
      config, _ = instance.load([:proc])
      expect(config[:foo]).to eq("yep")
      expect(config[:v2]).to eq(true)
    end

    it "should keep track of warnings and errors" do
      test_loader_v2 = Class.new(test_loader) do
        def self.upgrade(old)
          new = old.dup
          new[:v2] = true

          [new, ["foo!"], ["bar!"]]
        end
      end

      versions.register("2") { test_loader_v2 }
      version_order << "2"

      # Load a version 1 proc, and verify it is upgraded to version 2
      proc = lambda { |config| config[:foo] = "yep" }
      instance.set(:proc, [["1", proc]])
      config, warnings, errors = instance.load([:proc])
      expect(config[:foo]).to eq("yep")
      expect(config[:v2]).to eq(true)
      expect(warnings).to eq(["foo!"])
      expect(errors).to eq(["bar!"])
    end
  end

  describe "loading edge cases" do
    it "should only run the same proc once" do
      count = 0
      proc = Proc.new do |config|
        config[:foo] = "yep"
        count += 1
      end

      instance.set(:proc, [[current_version, proc]])

      5.times do
        result, _ = instance.load([:proc])

        # Verify the config result
        expect(result[:foo]).to eq("yep")

        # Verify the count is only one
        expect(count).to eq(1)
      end
    end

    it "should only load configuration files once" do
      $_config_data = 0

      # We test both setting a file multiple times as well as multiple
      # loads, since both should not cache the data.
      file = temporary_file("$_config_data += 1")
      5.times { instance.set(:file, file) }
      5.times { instance.load([:file]) }

      expect($_config_data).to eq(1)
    end

    it "should not clear the cache if setting to the same value multiple times" do
      $_config_data = 0

      file = temporary_file("$_config_data += 1")

      instance.set(:proc, file)
      5.times { instance.load([:proc]) }

      instance.set(:proc, file)
      5.times { instance.load([:proc]) }

      expect($_config_data).to eq(1)
    end

    it "should raise proper error if there is a syntax error in a Vagrantfile" do
      expect { instance.set(:file, temporary_file("Vagrant:^Config")) }.
        to raise_exception(Vagrant::Errors::VagrantfileSyntaxError)
    end

    it "should raise a proper error if there is a problem with the Vagrantfile" do
      expect { instance.set(:file, temporary_file("foo")) }.
        to raise_exception(Vagrant::Errors::VagrantfileLoadError)
    end
  end
end
