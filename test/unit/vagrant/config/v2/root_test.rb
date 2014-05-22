require "set"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Config::V2::Root do
  include_context "unit"

  it "should provide access to config objects" do
    foo_class = Class.new
    map       = { foo: foo_class }

    instance  = described_class.new(map)
    foo       = instance.foo
    expect(foo).to be_kind_of(foo_class)
    expect(instance.foo).to eql(foo)
  end

  it "record a missing key call if invalid key used" do
    instance = described_class.new({})
    expect { instance.foo }.to_not raise_error
    expect(instance.__internal_state["missing_key_calls"].include?("foo")).to be
  end

  it "returns a dummy config for a missing key" do
    instance = described_class.new({})
    expect { instance.foo.foo = "bar" }.to_not raise_error
  end

  it "can be created with initial state" do
    instance = described_class.new({}, { foo: "bar" })
    expect(instance.foo).to eq("bar")
  end

  it "should return internal state" do
    map      = { "foo" => Object, "bar" => Object }
    instance = described_class.new(map)
    expect(instance.__internal_state).to eq({
      "config_map"        => map,
      "keys"              => {},
      "missing_key_calls" => Set.new
    })
  end

  describe "#finalize!" do
    it "should call #finalize!" do
      foo_class = Class.new(Vagrant.plugin("2", "config")) do
        attr_accessor :foo

        def finalize!
          @foo = "SET"
        end
      end

      map = { foo: foo_class }
      instance = described_class.new(map)
      instance.finalize!

      expect(instance.foo.foo).to eq("SET")
    end

    it "should call #_finalize!" do
      klass = Class.new(Vagrant.plugin("2", "config"))

      expect_any_instance_of(klass).to receive(:finalize!)
      expect_any_instance_of(klass).to receive(:_finalize!)

      map = { foo: klass }
      instance = described_class.new(map)
      instance.finalize!
    end
  end

  describe "validation" do
    let(:instance) do
      map = { foo: Object, bar: Object }
      described_class.new(map)
    end

    it "should return nil if valid" do
      expect(instance.validate({})).to eq({})
    end

    it "should return errors if invalid" do
      errors = { "foo" => ["errors!"] }
      env    = { "errors" => errors }
      foo    = instance.foo
      def foo.validate(env)
        env["errors"]
      end

      expect(instance.validate(env)).to eq(errors)
    end

    it "should merge errors via array concat if matching keys" do
      errors = { "foo" => ["errors!"] }
      env    = { "errors" => errors }
      foo    = instance.foo
      bar    = instance.bar
      def foo.validate(env)
        env["errors"]
      end

      def bar.validate(env)
        env["errors"].merge({ "bar" => ["bar"] })
      end

      expected_errors = {
        "foo" => ["errors!", "errors!"],
        "bar" => ["bar"]
      }

      expect(instance.validate(env)).to eq(expected_errors)
    end

    it "shouldn't count empty keys" do
      errors = { "foo" => [] }
      env    = { "errors" => errors }
      foo    = instance.foo
      def foo.validate(env)
        env["errors"]
      end

      expect(instance.validate(env)).to eq({})
    end
  end
end
