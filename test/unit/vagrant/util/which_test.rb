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
    savepath = ENV['PATH']
    ENV['PATH'] = dir.to_s
    block.call filename + test_extension
    ENV['PATH'] = savepath

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
end
