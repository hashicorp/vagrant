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
      key: "value",
      another_value: "foo"
    }

    expect(klass.scoped_hash_override(original, "foo")).to eq(original)
  end

  it "should override if the scope matches" do
    original = {
      key: "value",
      scope__key: "replaced"
    }

    expected = {
      key: "replaced",
      scope__key: "replaced"
    }

    expect(klass.scoped_hash_override(original, "scope")).to eq(expected)
  end

  it "should ignore non-matching scopes" do
    original = {
      key: "value",
      scope__key: "replaced",
      another__key: "value"
    }

    expected = {
      key: "replaced",
      scope__key: "replaced",
      another__key: "value"
    }

    expect(klass.scoped_hash_override(original, "scope")).to eq(expected)
  end
end
