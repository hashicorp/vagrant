require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/deep_merge'

describe Vagrant::Util::DeepMerge do
  it "should deep merge hashes" do
    original = {
      "foo" => {
        "bar" => "baz",
      },
      "bar" => "blah",
    }

    other = {
      "foo" => {
        "bar" => "new",
      },
    }

    result = described_class.deep_merge(original, other)
    expect(result).to_not equal(original)
    expect(result).to eq({
      "foo" => {
        "bar" => "new",
      },
      "bar" => "blah",
    })
  end
end
