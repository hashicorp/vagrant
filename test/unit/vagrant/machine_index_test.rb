require "json"
require "pathname"
require "tempfile"

require File.expand_path("../../base", __FILE__)

require "vagrant/machine_index"

describe Vagrant::MachineIndex do
  include_context "unit"

  let(:data_dir) { temporary_dir }
  let(:entry_klass) { Vagrant::MachineIndex::Entry }

  let(:new_entry) do
    entry_klass.new.tap do |e|
      e.name = "foo"
      e.vagrantfile_path = "/bar"
    end
  end

  subject { described_class.new(data_dir) }

  it "raises an exception if the data file is corrupt" do
    data_dir.join("index").open("w") do |f|
      f.write(JSON.dump({}))
    end

    expect { subject }.
      to raise_error(Vagrant::Errors::CorruptMachineIndex)
  end

  it "raises an exception if the JSON is invalid" do
    data_dir.join("index").open("w") do |f|
      f.write("foo")
    end

    expect { subject }.
      to raise_error(Vagrant::Errors::CorruptMachineIndex)
  end

  describe "#each" do
    before do
      5.times do |i|
        e = entry_klass.new
        e.name = "entry-#{i}"
        e.vagrantfile_path = "/foo"
        subject.release(subject.set(e))
      end
    end

    it "should iterate over all the elements" do
      items = []

      subject = described_class.new(data_dir)
      subject.each do |entry|
        items << entry.name
      end

      items.sort!
      expect(items).to eq([
        "entry-0",
        "entry-1",
        "entry-2",
        "entry-3",
        "entry-4",
      ])
    end
  end

  describe "#get and #release" do
    before do
      data = {
        "version" => 1,
        "machines" => {
          "bar" => {
            "name" => "default",
            "provider" => "vmware",
            "local_data_path" => "/foo",
            "vagrantfile_path" => "/foo/bar/baz",
            "state" => "running",
            "updated_at" => "foo",
          },
          "baz" => {
            "name" => "default",
            "provider" => "vmware",
            "vagrantfile_path" => "/foo/bar/baz",
            "state" => "running",
            "updated_at" => "foo",
            "extra_data" => {
              "foo" => "bar",
            },
          },
        }
      }

      data_dir.join("index").open("w") do |f|
        f.write(JSON.dump(data))
      end
    end

    it "returns nil if the machine doesn't exist" do
      expect(subject.get("foo")).to be_nil
    end

    it "returns a valid entry if the machine exists" do
      result = subject.get("bar")

      expect(result.id).to eq("bar")
      expect(result.name).to eq("default")
      expect(result.provider).to eq("vmware")
      expect(result.local_data_path).to eq(Pathname.new("/foo"))
      expect(result.vagrantfile_path).to eq(Pathname.new("/foo/bar/baz"))
      expect(result.state).to eq("running")
      expect(result.updated_at).to eq("foo")
      expect(result.extra_data).to eq({})
    end

    it "returns a valid entry with extra data" do
      result = subject.get("baz")
      expect(result.id).to eq("baz")
      expect(result.extra_data).to eq({
        "foo" => "bar",
      })
    end

    it "returns a valid entry by unique prefix" do
      result = subject.get("b")

      expect(result).to_not be_nil
      expect(result.id).to eq("bar")
    end

    it "should include? by prefix" do
      expect(subject.include?("b")).to be_true
    end

    it "locks the entry so subsequent gets fail" do
      result = subject.get("bar")
      expect(result).to_not be_nil

      expect { subject.get("bar") }.
        to raise_error(Vagrant::Errors::MachineLocked)
    end

    it "can unlock a machine" do
      result = subject.get("bar")
      expect(result).to_not be_nil
      subject.release(result)

      result = subject.get("bar")
      expect(result).to_not be_nil
    end
  end

  describe "#include" do
    it "should not include non-existent things" do
      expect(subject.include?("foo")).to be_false
    end

    it "should include created entries" do
      result = subject.set(new_entry)
      expect(result.id).to_not be_empty
      subject.release(result)

      subject = described_class.new(data_dir)
      expect(subject.include?(result.id)).to be_true
    end
  end

  describe "#set and #get and #delete" do
    it "adds a new entry" do
      result = subject.set(new_entry)
      expect(result.id).to_not be_empty

      # It should be locked
      expect { subject.get(result.id) }.
        to raise_error(Vagrant::Errors::MachineLocked)

      # Get it froma new class and check the results
      subject.release(result)
      subject = described_class.new(data_dir)
      entry   = subject.get(result.id)
      expect(entry).to_not be_nil
      expect(entry.name).to eq("foo")

      # TODO: test that updated_at is set
    end

    it "can delete an entry" do
      result = subject.set(new_entry)
      expect(result.id).to_not be_empty
      subject.delete(result)

      # Get it from a new class and check the results
      subject = described_class.new(data_dir)
      entry   = subject.get(result.id)
      expect(entry).to be_nil
    end

    it "can delete an entry that doesn't exist" do
      e = entry_klass.new
      expect(subject.delete(e)).to be_true
    end

    it "updates an existing entry" do
      entry = entry_klass.new
      entry.name = "foo"
      entry.vagrantfile_path = "/bar"

      result = subject.set(entry)
      expect(result.id).to_not be_empty

      result.name = "bar"
      result.extra_data["foo"] = "bar"

      nextresult = subject.set(result)
      expect(nextresult.id).to eq(result.id)

      # Release it so we can test the contents
      subject.release(nextresult)

      # Get it froma new class and check the results
      subject = described_class.new(data_dir)
      entry   = subject.get(result.id)
      expect(entry).to_not be_nil
      expect(entry.name).to eq("bar")
      expect(entry.extra_data).to eq({
        "foo" => "bar",
      })
    end

    it "updates an existing directory if the name, provider, and path are the same" do
      entry = entry_klass.new
      entry.name = "foo"
      entry.provider = "bar"
      entry.vagrantfile_path = "/bar"
      entry.state = "foo"

      result = subject.set(entry)
      expect(result.id).to_not be_empty

      # Release it so we can modify it
      subject.release(result)

      entry2 = entry_klass.new
      entry2.name = entry.name
      entry2.provider = entry.provider
      entry2.vagrantfile_path = entry.vagrantfile_path
      entry2.state = "bar"
      expect(entry2.id).to be_nil

      nextresult = subject.set(entry2)
      expect(nextresult.id).to eq(result.id)

      # Release it so we can test the contents
      subject.release(nextresult)

      # Get it from a new class and check the results
      subject = described_class.new(data_dir)
      entry   = subject.get(result.id)
      expect(entry).to_not be_nil
      expect(entry.name).to eq(entry2.name)
      expect(entry.state).to eq(entry2.state)
    end
  end
end

describe Vagrant::MachineIndex::Entry do
  include_context "unit"

  let(:env) {
    iso_env = isolated_environment
    iso_env.vagrantfile(vagrantfile)
    iso_env.create_vagrant_env
  }

  let(:vagrantfile) { "" }

  describe "#valid?" do
    let(:machine) { env.machine(:default, :dummy) }

    subject do
      described_class.new.tap do |e|
        e.name = "default"
        e.provider = "dummy"
        e.vagrantfile_path = env.root_path
      end
    end

    it "should be valid with a valid entry" do
      machine.id = "foo"
      expect(subject).to be_valid(env.home_path)
    end

    it "should be invalid if no Vagrantfile path is set" do
      subject.vagrantfile_path = nil
      expect(subject).to_not be_valid(env.home_path)
    end

    it "should be invalid if the Vagrantfile path does not exist" do
      subject.vagrantfile_path = Pathname.new("/i/should/not/exist")
      expect(subject).to_not be_valid(env.home_path)
    end

    it "should be invalid if the machine is inactive" do
      machine.id = nil
      expect(subject).to_not be_valid(env.home_path)
    end

    it "should be invalid if machine is not created" do
      machine.id = "foo"
      machine.provider.state = Vagrant::MachineState::NOT_CREATED_ID
      expect(subject).to_not be_valid(env.home_path)
    end

    context "with another active machine" do
      let(:vagrantfile) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.define "web"
          config.vm.define "db"
        end
        VF
      end

      it "should be invalid if the wrong machine is active only" do
        m = env.machine(:web, :dummy)
        m.id = "foo"

        subject.name = "db"
        expect(subject).to_not be_valid(env.home_path)
      end

      it "should be valid if the correct machine is active" do
        env.machine(:web, :dummy).id = "foo"
        env.machine(:db, :dummy).id = "foo"

        subject.name = "db"
        expect(subject).to be_valid(env.home_path)
      end
    end
  end
end
