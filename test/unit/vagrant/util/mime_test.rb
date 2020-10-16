require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/mime'
require 'mime/types'

describe Vagrant::Util::Mime::Multipart do

  subject { described_class }

  let(:time) { 603907018 }
  let(:secure_random) { "123qwe" }

  before do 
    allow(Time).to receive(:now).and_return(time)
    allow(SecureRandom).to receive(:alphanumeric).and_return(secure_random)
  end

  it "can add headers" do
    mime = subject.new()
    mime.headers["Mime-Version"] = "1.0"
    expected_string = "Content-ID: <#{time}@#{secure_random}.local>
Content-Type: multipart/mixed; boundary=Boundary_#{secure_random}
Mime-Version: 1.0

--Boundary_#{secure_random}
"
    expect(mime.to_s).to eq(expected_string)
  end

  it "can add content" do
    mime = subject.new()
    mime.add("something")
    expected_string = "Content-ID: <#{time}@#{secure_random}.local>
Content-Type: multipart/mixed; boundary=Boundary_#{secure_random}

--Boundary_#{secure_random}
something
--Boundary_#{secure_random}
"
    expect(mime.to_s).to eq(expected_string)
  end

  it "can add Vagrant::Util::Mime::Entity content" do
    mime = subject.new()
    mime.add(Vagrant::Util::Mime::Entity.new("something", "text/cloud-config"))
    expected_string = "Content-ID: <#{time}@#{secure_random}.local>
Content-Type: multipart/mixed; boundary=Boundary_#{secure_random}

--Boundary_#{secure_random}
Content-ID: <#{time}@#{secure_random}.local>
Content-Type: text/cloud-config

something
--Boundary_#{secure_random}
"
    expect(mime.to_s).to eq(expected_string)
  end
end

describe Vagrant::Util::Mime::Entity do

  subject { described_class }

  let(:time) { 603907018 }
  let(:secure_random) { "123qwe" }

  before do 
    allow(Time).to receive(:now).and_return(time)
    allow(SecureRandom).to receive(:alphanumeric).and_return(secure_random)
  end

  it "registers the content type" do 
    subject.new("something", "text/cloud-config")
    expect(MIME::Types).to include("text/cloud-config")
  end

  it "outputs as a string" do
    entity = subject.new("something", "text/cloud-config")
    expected_string = "Content-ID: <#{time}@#{secure_random}.local>
Content-Type: text/cloud-config

something"
    expect(entity.to_s).to eq(expected_string)
  end
end
