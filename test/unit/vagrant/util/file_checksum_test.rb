require File.expand_path("../../../base", __FILE__)
require 'digest/md5'
require 'digest/sha1'

require 'vagrant/util/file_checksum'

describe FileChecksum do
  include_context "unit"

  let(:environment) { isolated_environment }

  it "should return a valid checksum for a file" do
    file = environment.workdir.join("file")
    file.open("w+") { |f| f.write("HELLO!") }

    # Check multiple digests
    instance = described_class.new(file, Digest::MD5)
    expect(instance.checksum).to eq("9ac96c64417b5976a58839eceaa77956")

    instance = described_class.new(file, Digest::SHA1)
    expect(instance.checksum).to eq("264b207c7913e461c43d0f63d2512f4017af4755")
  end
end
