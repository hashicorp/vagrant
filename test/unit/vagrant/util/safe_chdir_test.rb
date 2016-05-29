require 'tmpdir'

require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/safe_chdir'

describe Vagrant::Util::SafeChdir do
  let(:temp_dir) { Dir.mktmpdir("vagrant-test-util-safe-chdir") }
  let(:temp_dir2) { Dir.mktmpdir("vagrant-test-util-safe-chdir-2") }

  after do
    FileUtils.rm_rf(temp_dir)
    FileUtils.rm_rf(temp_dir2)
  end

  it "should change directories" do
    expected = nil
    result   = nil

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

    Dir.chdir(temp_dir) do
      expected = Dir.pwd
    end

    expect do
      described_class.safe_chdir(temp_dir2) do
        described_class.safe_chdir(temp_dir) do
          result = Dir.pwd
        end
      end
    end.to_not raise_error

    expect(result).to eq(expected)
  end
end
