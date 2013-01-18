require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Config::V2::Root do
  include_context "unit"

  it "should provide access to config objects" do
    foo_class = Class.new
    map       = { :foo => foo_class }

    instance  = described_class.new(map)
    foo       = instance.foo
    foo.should be_kind_of(foo_class)
    instance.foo.should eql(foo)
  end

  it "should raise a proper NoMethodError if a config key doesn't exist" do
    instance = described_class.new({})
    expect { instance.foo }.to raise_error(NoMethodError)
  end

  it "can be created with initial state" do
    instance = described_class.new({}, { :foo => "bar" })
    instance.foo.should == "bar"
  end

  it "should return internal state" do
    map      = { "foo" => Object, "bar" => Object }
    instance = described_class.new(map)
    instance.__internal_state.should == {
      "config_map" => map,
      "keys"       => {}
    }
  end

  describe "validation" do
    let(:instance) do
      map = { :foo => Object, :bar => Object }
      described_class.new(map)
    end

    it "should return nil if valid" do
      instance.validate({}).should == {}
    end

    it "should return errors if invalid" do
      errors = { "foo" => ["errors!"] }
      env    = { "errors" => errors }
      foo    = instance.foo
      def foo.validate(env)
        env["errors"]
      end

      instance.validate(env).should == errors
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

      instance.validate(env).should == expected_errors
    end

    it "shouldn't count empty keys" do
      errors = { "foo" => [] }
      env    = { "errors" => errors }
      foo    = instance.foo
      def foo.validate(env)
        env["errors"]
      end

      instance.validate(env).should == {}
    end
  end
end
