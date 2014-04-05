require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::BoxCheckOutdated do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:env) { {
    box_collection: iso_vagrant_env.boxes,
    machine: machine,
    ui: Vagrant::UI::Silent.new,
  } }

  subject { described_class.new(app, env) }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    isolated_environment.tap do |env|
      env.vagrantfile("")
    end
  end

  let(:iso_vagrant_env) { iso_env.create_vagrant_env }

  let(:box) do
    box_dir = iso_env.box3("foo", "1.0", :virtualbox)
    Vagrant::Box.new("foo", :virtualbox, "1.0", box_dir).tap do |b|
      b.stub(has_update?: nil)
    end
  end

  let(:machine) do
    m = iso_vagrant_env.machine(iso_vagrant_env.machine_names[0], :dummy)
    m.config.vm.box_check_update = true
    m
  end

  before do
    machine.stub(box: box)
  end

  context "disabling outdated checking" do
    it "doesn't check" do
      machine.config.vm.box_check_update = false

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env).to_not have_key(:box_outdated)
    end

    it "checks if forced" do
      machine.config.vm.box_check_update = false
      env[:box_outdated_force] = true

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env).to have_key(:box_outdated)
    end
  end

  context "no box" do
    it "raises an exception if the machine doesn't have a box yet" do
      machine.stub(box: nil)

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env).to_not have_key(:box_outdated)
    end
  end

  context "with a non-versioned box" do
    it "does nothing" do
      box.stub(metadata_url: nil)
      box.stub(version: "0")

      expect(app).to receive(:call).once
      expect(box).to receive(:has_update?).never

      subject.call(env)
    end
  end

  context "with a box" do
    it "sets env if no update" do
      expect(box).to receive(:has_update?).and_return(nil)

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env[:box_outdated]).to be_false
    end

    it "sets env if there is an update" do
      md = Vagrant::BoxMetadata.new(StringIO.new(<<-RAW))
      {
        "name": "foo",
        "versions": [
          {
            "version": "1.0"
          },
          {
            "version": "1.1",
            "providers": [
              {
                "name": "virtualbox",
                "url": "bar"
              }
            ]
          }
        ]
      }
      RAW

      expect(box).to receive(:has_update?).with(machine.config.vm.box_version).
        and_return([md, md.version("1.1"), md.version("1.1").provider("virtualbox")])

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env[:box_outdated]).to be_true
    end

    it "has an update if it is local" do
      iso_env.box3("foo", "1.1", :virtualbox)

      expect(box).to receive(:has_update?).and_return(nil)

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env[:box_outdated]).to be_true
    end

    it "does not have a local update if not within constraints" do
      iso_env.box3("foo", "1.1", :virtualbox)

      machine.config.vm.box_version = "> 1.0, < 1.1"

      expect(box).to receive(:has_update?).and_return(nil)

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env[:box_outdated]).to be_false
    end

    it "does nothing if metadata download fails" do
      expect(box).to receive(:has_update?).and_raise(
        Vagrant::Errors::BoxMetadataDownloadError.new(message: "foo"))

      expect(app).to receive(:call).once

      subject.call(env)

      expect(env[:box_outdated]).to be_false
    end

    it "raises error if has_update? errors" do
      expect(box).to receive(:has_update?).and_raise(Vagrant::Errors::VagrantError)

      expect(app).to receive(:call).never

      expect { subject.call(env) }.to raise_error(Vagrant::Errors::VagrantError)
    end

    it "doesn't raise an error if ignore errors is on" do
      env[:box_outdated_ignore_errors] = true

      expect(box).to receive(:has_update?).and_raise(Vagrant::Errors::VagrantError)
      expect(app).to receive(:call).with(env).once

      expect { subject.call(env) }.to_not raise_error
    end
  end
end
