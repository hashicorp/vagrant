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
      allow(b).to receive(:has_update?).and_return(nil)
    end
  end

  let(:machine) do
    m = iso_vagrant_env.machine(iso_vagrant_env.machine_names[0], :dummy)
    m.config.vm.box_check_update = true
    m
  end

  before do
    allow(machine).to receive(:box).and_return(box)
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
      expect(box).to receive(:has_update?)

      subject.call(env)

      expect(env).to have_key(:box_outdated)
    end

    it "checks if not forced" do
      machine.config.vm.box_check_update = false
      env[:box_outdated_force] = false

      expect(app).to receive(:call).with(env).once

      subject.call(env)
    end
  end

  context "no box" do
    it "raises an exception if the machine doesn't have a box yet" do
      allow(machine).to receive(:box).and_return(nil)

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env).to_not have_key(:box_outdated)
    end
  end

  context "with a non-versioned box" do
    it "does nothing" do
      allow(box).to receive(:metadata_url).and_return(nil)
      allow(box).to receive(:version).and_return("0")

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

      expect(env[:box_outdated]).to be(false)
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

      expect(box).to receive(:has_update?).with(machine.config.vm.box_version,
          {download_options:
            {automatic_check: true, ca_cert: nil, ca_path: nil, client_cert: nil, insecure: false}}).
        and_return([md, md.version("1.1"), md.version("1.1").provider("virtualbox")])

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env[:box_outdated]).to be(true)
    end

    it "has an update if it is local" do
      iso_env.box3("foo", "1.1", :virtualbox)

      expect(box).to receive(:has_update?).and_return(nil)

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env[:box_outdated]).to be(true)
    end

    context "both local and remote update exist" do
      it "should prompt user to update" do
        iso_env.box3("foo", "1.1", :virtualbox)

        md = Vagrant::BoxMetadata.new(StringIO.new(<<-RAW))
        {
          "name": "foo",
          "versions": [
            {
              "version": "1.2",
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

        expect(box).to receive(:has_update?).with(machine.config.vm.box_version,
            {download_options:
              {automatic_check: true, ca_cert: nil, ca_path: nil, client_cert: nil, insecure: false}}).
          and_return([md, md.version("1.2"), md.version("1.2").provider("virtualbox")])

        allow(I18n).to receive(:t) { :ok }
        expect(I18n).to receive(:t).with(/box_outdated_single/, hash_including(latest: "1.2")).once

        expect(app).to receive(:call).with(env).once

        subject.call(env)
      end
    end

    it "does not have a local update if not within constraints" do
      iso_env.box3("foo", "1.1", :virtualbox)

      machine.config.vm.box_version = "> 1.0, < 1.1"

      expect(box).to receive(:has_update?).and_return(nil)

      expect(app).to receive(:call).with(env).once

      subject.call(env)

      expect(env[:box_outdated]).to be(false)
    end

    it "does nothing if metadata download fails" do
      expect(box).to receive(:has_update?).and_raise(
        Vagrant::Errors::BoxMetadataDownloadError.new(message: "foo"))

      expect(app).to receive(:call).once

      subject.call(env)

      expect(env[:box_outdated]).to be(false)
    end

    it "does nothing if metadata cannot be parsed" do
      expect(box).to receive(:has_update?).and_raise(
        Vagrant::Errors::BoxMetadataMalformed.new(error: "Whoopsie"))

      expect(app).to receive(:call).once

      subject.call(env)

      expect(env[:box_outdated]).to be(false)
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

    context "when machine download options are specified" do
      before do
        machine.config.vm.box_download_ca_cert = "foo"
        machine.config.vm.box_download_ca_path = "bar"
        machine.config.vm.box_download_client_cert = "baz"
        machine.config.vm.box_download_insecure = true
      end

      it "uses download options from machine" do
        expect(box).to receive(:has_update?).with(machine.config.vm.box_version,
          {download_options:
            {automatic_check: true, ca_cert: "foo", ca_path: "bar", client_cert: "baz", insecure: true}})

        expect(app).to receive(:call).with(env).once

        subject.call(env)
      end

      it "overrides download options from machine with options from env" do
        expect(box).to receive(:has_update?).with(machine.config.vm.box_version,
          {download_options:
            {automatic_check: true, ca_cert: "oof", ca_path: "rab", client_cert: "zab", insecure: false}})

        env[:ca_cert] = "oof"
        env[:ca_path] = "rab"
        env[:client_cert] = "zab"
        env[:insecure] = false
        expect(app).to receive(:call).with(env).once

        subject.call(env)
      end
    end
  end

  describe ".check_outdated_local" do
    let(:updated_box) do
      box_dir = iso_env.box3("foo", "1.1", :virtualbox)
      Vagrant::Box.new("foo", :virtualbox, "1.1", box_dir).tap do |b|
        allow(b).to receive(:has_update?).and_return(nil)
      end
    end

    it "should return the updated box if it is already installed" do
      expect(env[:box_collection]).to receive(:find).with("foo", :virtualbox, "> 1.0").and_return(updated_box)

      local_update = subject.check_outdated_local(env)

      expect(local_update).to eq(updated_box)
    end
  end
end
