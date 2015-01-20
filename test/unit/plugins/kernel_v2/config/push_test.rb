require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/push")

describe VagrantPlugins::Kernel_V2::PushConfig do
  include_context "unit"

  subject { described_class.new }

  describe "#define" do
    let(:pushes) { subject.instance_variable_get(:@__defined_pushes) }

    it "pushes the strategy and block onto the defined pushes array" do
      subject.define("foo") { "bar" }
      subject.define("foo") { "zip" }
      subject.define("foo") { "zap" }

      expect(pushes.size).to eq(1)
      expect(pushes[:foo].size).to eq(3)
      expect(pushes[:foo][0]).to be_a(Array)
      expect(pushes[:foo][0][0]).to eq(:foo)
      expect(pushes[:foo][0][1]).to be_a(Proc)
    end

    context "when no strategy is given" do
      it "defaults to the name" do
        subject.define("foo") { "bar" }

        expect(pushes.size).to eq(1)
        expect(pushes[:foo].size).to eq(1)
        expect(pushes[:foo][0]).to be_a(Array)
        expect(pushes[:foo][0][0]).to eq(:foo)
        expect(pushes[:foo][0][1]).to be_a(Proc)
      end
    end

    context "when a strategy is given" do
      it "uses the strategy" do
        subject.define("foo", strategy: "bacon") { "bar" }

        expect(pushes.size).to eq(1)
        expect(pushes[:foo].size).to eq(1)
        expect(pushes[:foo][0]).to be_a(Array)
        expect(pushes[:foo][0][0]).to eq(:bacon)
        expect(pushes[:foo][0][1]).to be_a(Proc)
      end
    end
  end

  describe "#merge" do
    it "appends defined pushes" do
      a = described_class.new.tap do |i|
        i.define("foo") { "bar" }
        i.define("bar") { "bar" }
      end
      b = described_class.new.tap do |i|
        i.define("foo") { "zip" }
      end

      result = a.merge(b)
      pushes = result.instance_variable_get(:@__defined_pushes)

      expect(pushes[:foo]).to be_a(Array)
      expect(pushes[:foo].size).to eq(2)

      expect(pushes[:bar]).to be_a(Array)
      expect(pushes[:bar].size).to eq(1)
    end
  end

  describe "#__compiled_pushes" do
    it "raises an exception if not finalized" do
      subject.instance_variable_set(:@__finalized, false)
      expect { subject.__compiled_pushes }.to raise_error
    end

    it "returns a copy of the compiled pushes" do
      pushes =  { foo: "bar" }
      subject.instance_variable_set(:@__finalized, true)
      subject.instance_variable_set(:@__compiled_pushes, pushes)

      expect(subject.__compiled_pushes).to_not be(pushes)
      expect(subject.__compiled_pushes).to eq(pushes)
    end
  end

  describe "#finalize!" do
    let(:pushes) { a.merge(b).tap { |r| r.finalize! }.__compiled_pushes }
    let(:key)    { pushes[:foo][0] }
    let(:config) { pushes[:foo][1] }
    let(:unset)  { Vagrant.plugin("2", :config).const_get(:UNSET_VALUE) }
    let(:dummy_klass) { Vagrant::Config::V2::DummyConfig }

    before do
      register_plugin("2") do |plugin|
        plugin.name "foo"

        plugin.push(:foo) do
          Class.new(Vagrant.plugin("2", :push))
        end

        plugin.config(:foo, :push) do
          Class.new(Vagrant.plugin("2", :config)) do
            attr_accessor :bar
            attr_accessor :zip

            def initialize
              @bar = self.class.const_get(:UNSET_VALUE)
              @zip = self.class.const_get(:UNSET_VALUE)
            end
          end
        end
      end
    end

    it "compiles the proper configuration with a single strategy" do
      instance = described_class.new.tap do |i|
        i.define "foo"
      end

      instance.finalize!

      pushes = instance.__compiled_pushes
      strategy, config = pushes[:foo]
      expect(strategy).to eq(:foo)
      expect(config.bar).to be(unset)
    end

    it "compiles the proper configuration with a single strategy and block" do
      instance = described_class.new.tap do |i|
        i.define "foo" do |b|
          b.bar = 42
        end
      end

      instance.finalize!

      pushes = instance.__compiled_pushes
      strategy, config = pushes[:foo]
      expect(strategy).to eq(:foo)
      expect(config.bar).to eq(42)
    end

    it "compiles the proper config with a name and explicit strategy" do
      instance = described_class.new.tap do |i|
        i.define "bar", strategy: "foo"
      end

      instance.finalize!

      pushes = instance.__compiled_pushes
      strategy, config = pushes[:bar]
      expect(strategy).to eq(:foo)
      expect(config.bar).to be(unset)
    end

    it "compiles the proper config with a name and explicit strategy with block" do
      instance = described_class.new.tap do |i|
        i.define "bar", strategy: "foo" do |b|
          b.bar = 42
        end
      end

      instance.finalize!

      pushes = instance.__compiled_pushes
      strategy, config = pushes[:bar]
      expect(strategy).to eq(:foo)
      expect(config.bar).to eq(42)
    end

    context "with the same name but different strategy" do
      context "with no block" do
        let(:a) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "bar")
          end
        end

        let(:b) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "zip")
          end
        end

        it "chooses the last config" do
          expect(key).to eq(:zip)
          expect(config).to be_kind_of(dummy_klass)
        end
      end

      context "with a block" do
        let(:a) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "bar") do |p|
              p.bar = "a"
            end
          end
        end

        let(:b) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "zip") do |p|
              p.zip = "b"
            end
          end
        end

        it "chooses the last config" do
          expect(key).to eq(:zip)
          expect(config).to be_kind_of(dummy_klass)
        end
      end

      context "with a block, then no block" do
        let(:a) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "bar") do |p|
              p.bar, p.zip = "a", "a"
            end
          end
        end

        let(:b) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "zip")
          end
        end

        it "chooses the last config" do
          expect(key).to eq(:zip)
          expect(config).to be_kind_of(dummy_klass)
        end
      end

      context "with no block, then a block" do
        let(:a) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "bar")
          end
        end

        let(:b) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "zip") do |p|
              p.bar, p.zip = "b", "b"
            end
          end
        end

        it "chooses the last config" do
          expect(key).to eq(:zip)
          expect(config).to be_kind_of(dummy_klass)
        end
      end
    end

    context "with the same name twice" do
      context "with no block" do
        let(:a) do
          described_class.new.tap do |i|
            i.define("foo")
          end
        end

        let(:b) do
          described_class.new.tap do |i|
            i.define("foo")
          end
        end

        it "merges the configs" do
          expect(key).to eq(:foo)
          expect(config.bar).to be(unset)
          expect(config.zip).to be(unset)
        end
      end

      context "with a block" do
        let(:a) do
          described_class.new.tap do |i|
            i.define("foo") do |p|
              p.bar = "a"
            end
          end
        end

        let(:b) do
          described_class.new.tap do |i|
            i.define("foo") do |p|
              p.zip = "b"
            end
          end
        end

        it "merges the configs" do
          expect(key).to eq(:foo)
          expect(config.bar).to eq("a")
          expect(config.zip).to eq("b")
        end
      end

      context "with a block, then no block" do
        let(:a) do
          described_class.new.tap do |i|
            i.define("foo") do |p|
              p.bar = "a"
            end
          end
        end

        let(:b) do
          described_class.new.tap do |i|
            i.define("foo")
          end
        end

        it "merges the configs" do
          expect(key).to eq(:foo)
          expect(config.bar).to eq("a")
          expect(config.zip).to be(unset)
        end
      end

      context "with no block, then a block" do
        let(:a) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "bar")
          end
        end

        let(:b) do
          described_class.new.tap do |i|
            i.define("foo", strategy: "zip") do |p|
              p.zip = "b"
            end
          end
        end

        it "merges the configs" do
          expect(key).to eq(:zip)
          expect(config).to be_kind_of(dummy_klass)
        end
      end
    end

    it "sets @__finalized to true" do
      subject.finalize!
      expect(subject.instance_variable_get(:@__finalized)).to be(true)
    end
  end
end
