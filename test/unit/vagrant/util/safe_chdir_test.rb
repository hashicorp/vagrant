require 'tmpdir'

require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/safe_chdir'

describe Vagrant::Util::SafeChdir do
  it "should change directories" do
    expected = nil
    result   = nil
    temp_dir = Dir.mktmpdir

    Dir.chdir(temp_dir) do
      expected = Dir.pwd
    end

    described_class.safe_chdir(temp_dir) do
      result = Dir.pwd
    end

    expect(result).to eq(expected)
  end

  it "should allow recursive chdir" do
    expected  = nil
    result    = nil
    temp_path = Dir.mktmpdir

    Dir.chdir(temp_path) do
      expected = Dir.pwd
    end

    expect do
      described_class.safe_chdir(Dir.mktmpdir) do
        described_class.safe_chdir(temp_path) do
          result = Dir.pwd
        end
      end
    end.to_not raise_error

    expect(result).to eq(expected)
  end
end
