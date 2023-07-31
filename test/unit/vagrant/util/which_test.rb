# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/platform'
require 'vagrant/util/which'

describe Vagrant::Util::Which do
  def tester (file_extension, test_extension, mode, &block)
    # create file in temp directory
    filename = '__vagrant_unit_test__'
    dir = Dir.tmpdir
    file = Pathname(dir) + (filename + file_extension)
    file.open("w") { |f| f.write("#") }
    file.chmod(mode)

    # set the path to the directory where the file is located
    allow(ENV).to receive(:[]).with("PATH").and_return(dir.to_s)
    block.call filename + test_extension

    file.unlink
  end

  it "should return a path for an executable file" do
    tester '.bat', '.bat', 0755 do |name|
      expect(described_class.which(name)).not_to be_nil
    end
  end

  if Vagrant::Util::Platform.windows?
    it "should return a path for a Windows executable file" do
      tester '.bat', '', 0755 do |name|
        expect(described_class.which(name)).not_to be_nil
      end
    end
  end

  it "should return nil for a non-executable file" do
    tester '.txt', '.txt', 0644 do |name|
      expect(described_class.which(name)).to be_nil
    end
  end

  context "original_path option" do
    before{ allow(ENV).to receive(:[]).with("PATH").and_return("") }

    it "should use the original path when instructed" do
      expect(ENV).to receive(:fetch).with("VAGRANT_OLD_ENV_PATH", any_args).and_return("")
      described_class.which("file", original_path: true)
    end
  end
end
