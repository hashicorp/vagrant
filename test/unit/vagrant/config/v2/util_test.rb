require File.expand_path("../../../../base", __FILE__)

require "vagrant/config/v2/util"

describe Vagrant::Config::V2::Util do
  describe "merging errors" do
    it "should merge matching keys and leave the rest alone" do
      first  = { "one" => ["foo"], "two" => ["two"] }
      second = { "one" => ["bar"], "three" => ["three"] }

      expected = {
        "one" => ["foo", "bar"],
        "two" => ["two"],
        "three" => ["three"]
      }

      result = described_class.merge_errors(first, second)
      expect(result).to eq(expected)
    end
  end
end
