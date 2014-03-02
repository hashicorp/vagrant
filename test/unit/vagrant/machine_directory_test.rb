require "json"
require "pathname"
require "tempfile"

require File.expand_path("../../base", __FILE__)

require "vagrant/machine_index"

describe Vagrant::MachineIndex do
  include_context "unit"

  let(:data_file) { temporary_file }

  subject { described_class.new(data_file) }

  it "raises an exception if the data file is corrupt" do
    data_file.open("w") do |f|
      f.write(JSON.dump({}))
    end

    expect { subject }.
      to raise_error(Vagrant::Errors::CorruptMachineIndex)
  end

  it "raises an exception if the JSON is invalid" do
    data_file.open("w") do |f|
      f.write("foo")
    end

    expect { subject }.
      to raise_error(Vagrant::Errors::CorruptMachineIndex)
  end

  describe "#[]" do
    before do
      data = {
        "version" => 1,
        "machines" => {
          "bar" => {
            "name" => "default",
            "provider" => "vmware",
            "vagrantfile_path" => "/foo/bar/baz",
            "state" => "running",
            "updated_at" => "foo",
          }
        }
      }

      data_file.open("w") do |f|
        f.write(JSON.dump(data))
      end
    end

    it "returns nil if the machine doesn't exist" do
      expect(subject["foo"]).to be_nil
    end

    it "returns a valid entry if the machine exists" do
      result = subject["bar"]

      expect(result.id).to eq("bar")
      expect(result.name).to eq("default")
      expect(result.provider).to eq("vmware")
      expect(result.vagrantfile_path).to eq(Pathname.new("/foo/bar/baz"))
      expect(result.state).to eq("running")
      expect(result.updated_at).to eq("foo")
    end
  end

  describe "#set and #[]" do
    let(:entry_klass) { Vagrant::MachineIndex::Entry }

    it "adds a new entry" do
      entry = entry_klass.new
      entry.name = "foo"
      entry.vagrantfile_path = "/bar"

      result = subject.set(entry)
      expect(result.id).to_not be_empty

      # Get it froma new class and check the results
      subject = described_class.new(data_file)
      entry   = subject[result.id]
      expect(entry).to_not be_nil
      expect(entry.name).to eq("foo")

      # TODO: test that updated_at is set
    end

    it "updates an existing entry" do
      entry = entry_klass.new
      entry.name = "foo"
      entry.vagrantfile_path = "/bar"

      result = subject.set(entry)
      expect(result.id).to_not be_empty

      result.name = "bar"

      nextresult = subject.set(result)
      expect(nextresult.id).to eq(result.id)

      # Get it froma new class and check the results
      subject = described_class.new(data_file)
      entry   = subject[result.id]
      expect(entry).to_not be_nil
      expect(entry.name).to eq("bar")
    end
  end
end
