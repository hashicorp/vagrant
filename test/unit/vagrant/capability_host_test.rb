require File.expand_path("../../base", __FILE__)

require "vagrant/capability_host"

describe Vagrant::CapabilityHost do
  include_context "capability_helpers"

  subject do
    Class.new do
      extend Vagrant::CapabilityHost
    end
  end

  describe "#initialize_capabilities! and #capability_host_chain" do
    it "raises an error if an explicit host is not found" do
      expect { subject.initialize_capabilities!(:foo, {}, {}) }.
        to raise_error(Vagrant::Errors::CapabilityHostExplicitNotDetected)
    end

    it "raises an error if a host can't be detected" do
      hosts = {
        foo: [detect_class(false), nil],
        bar: [detect_class(false), :foo],
      }

      expect { subject.initialize_capabilities!(nil, hosts, {}) }.
        to raise_error(Vagrant::Errors::CapabilityHostNotDetected)
    end

    it "passes on extra args to the detect method" do
      klass = Class.new do
        def detect?(*args)
          raise "detect: #{args.inspect}"
        end
      end

      hosts = {
        foo: [klass, nil],
      }

      expect { subject.initialize_capabilities!(nil, hosts, {}, 1, 2) }.
        to raise_error(RuntimeError, "detect: [1, 2]")
    end

    it "detects a basic child" do
      hosts = {
        foo: [detect_class(false), nil],
        bar: [detect_class(true), nil],
        baz: [detect_class(false), nil],
      }

      subject.initialize_capabilities!(nil, hosts, {})

      chain = subject.capability_host_chain
      expect(chain.length).to eql(1)
      expect(chain[0][0]).to eql(:bar)
    end

    it "detects the host with the most parents (deepest) first" do
      hosts = {
        foo: [detect_class(true), nil],
        bar: [detect_class(true), :foo],
        baz: [detect_class(true), :bar],
        foo2: [detect_class(true), nil],
        bar2: [detect_class(true), :foo2],
      }

      subject.initialize_capabilities!(nil, hosts, {})

      chain = subject.capability_host_chain
      expect(chain.length).to eql(3)
      expect(chain.map(&:first)).to eql([:baz, :bar, :foo])
    end

    it "detects a forced host" do
      hosts = {
        foo: [detect_class(false), nil],
        bar: [detect_class(false), nil],
        baz: [detect_class(false), nil],
      }

      subject.initialize_capabilities!(:bar, hosts, {})

      chain = subject.capability_host_chain
      expect(chain.length).to eql(1)
      expect(chain[0][0]).to eql(:bar)
    end
  end

  describe "#capability?" do
    before do
      host  = nil
      hosts = {
        foo: [detect_class(true), nil],
        bar: [detect_class(true), :foo],
      }

      caps = {
        foo: { parent: Class.new },
        bar: { self: Class.new },
      }

      subject.initialize_capabilities!(host, hosts, caps)
    end

    it "does not have a non-existent capability" do
      expect(subject.capability?(:foo)).to be(false)
    end

    it "has capabilities of itself" do
      expect(subject.capability?(:self)).to be(true)
    end

    it "has capabilities of parent" do
      expect(subject.capability?(:parent)).to be(true)
    end
  end

  describe "capability" do
    let(:caps) { {} }

    def init
      host  = nil
      hosts = {
        foo: [detect_class(true), nil],
        bar: [detect_class(true), :foo],
      }

      subject.initialize_capabilities!(host, hosts, caps)
    end

    it "executes the capability" do
      caps[:bar] = { test: cap_instance(:test) }
      init

      expect { subject.capability(:test) }.
        to raise_error(RuntimeError, "cap: test []")
    end

    it "executes the capability with arguments" do
      caps[:bar] = { test: cap_instance(:test) }
      init

      expect { subject.capability(:test, 1) }.
        to raise_error(RuntimeError, "cap: test [1]")
    end

    it "raises an exception if the capability doesn't exist" do
      init

      expect { subject.capability(:what_is_this_i_dont_even) }.
        to raise_error(Vagrant::Errors::CapabilityNotFound)
    end

    it "raises an exception if the method doesn't exist on the module" do
      caps[:bar] = { test_is_corrupt: cap_instance(:test_is_corrupt, corrupt: true) }
      init

      expect { subject.capability(:test_is_corrupt) }.
        to raise_error(Vagrant::Errors::CapabilityInvalid)
    end
  end
end
