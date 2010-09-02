require "test_helper"

class ConfigBaseTest < Test::Unit::TestCase
  setup do
    @base = Vagrant::Config::Base.new
  end

  should "return a hash of instance variables" do
    data = { "foo" => "bar", "bar" => "baz" }

    data.each do |iv, value|
      @base.instance_variable_set("@#{iv}".to_sym, value)
    end

    result = @base.instance_variables_hash
    assert_equal data.length, result.length

    data.each do |iv, value|
      assert_equal value, result[iv]
    end
  end

  context "converting to JSON" do
    should "include magic `json_class`" do
      @iv_hash = { "foo" => "bar" }
      @base.expects(:instance_variables_hash).returns(@iv_hash)
      @json = { 'json_class' => @base.class.name }.merge(@iv_hash).to_json
      assert_equal @json, @base.to_json
    end

    should "not include env in the JSON hash" do
      @base.env = "FOO"
      hash = @base.instance_variables_hash
      assert !hash.has_key?(:env)
    end
  end
end
