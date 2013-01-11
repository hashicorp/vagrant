require File.expand_path("../../../base", __FILE__)

require "vagrant/util/scoped_hash_override"

describe Vagrant::Util::ScopedHashOverride do
  let(:klass) do
    Class.new do
      extend Vagrant::Util::ScopedHashOverride
    end
  end

  it "should not mess with non-overrides" do
    original = {
      :key => "value",
      :another_value => "foo"
    }

    klass.scoped_hash_override(original, "foo").should == original
  end

  it "should override if the scope matches" do
    original = {
      :key => "value",
      :scope__key => "replaced"
    }

    expected = {
      :key => "replaced"
    }

    klass.scoped_hash_override(original, "scope").should == expected
  end

  it "should ignore non-matching scopes" do
    original = {
      :key => "value",
      :scope__key => "replaced",
      :another__key => "value"
    }

    expected = {
      :key => "replaced",
      :another__key => "value"
    }

    klass.scoped_hash_override(original, "scope").should == expected
  end
end
