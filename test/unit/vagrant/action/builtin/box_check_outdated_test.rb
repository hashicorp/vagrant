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
    Vagrant::Box.new("foo", :virtualbox, "1.0", box_dir)
  end
  let(:machine) { iso_vagrant_env.machine(iso_vagrant_env.machine_names[0], :dummy) }

  context "no box" do
    it "raises an exception if the machine doesn't have a box yet" do
      machine.stub(box: nil)

      app.should_receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxOutdatedNoBox)
    end
  end

  context "without refreshing" do
    before do
      env[:box_outdated_refresh] = false

      machine.stub(box: box)
    end

    it "isn't outdated if there are no newer boxes" do
      iso_env.box3("foo", "0.5", :virtualbox)

      app.should_receive(:call).with(env)

      subject.call(env)

      expect(env[:box_outdated]).to be_false
    end

    it "is outdated if there are newer boxes" do
      iso_env.box3("foo", "1.5", :virtualbox)

      app.should_receive(:call).with(env)

      subject.call(env)

      expect(env[:box_outdated]).to be_true
    end
  end

  context "with refreshing" do
    before do
      env[:box_outdated_refresh] = true
    end

    context "no metadata URL" do
      let(:box) do
        box_dir = iso_env.box3("foo", "1.0", :virtualbox)
        Vagrant::Box.new("foo", :virtualbox, "1.0", box_dir)
      end

      before do
        machine.stub(box: box)
      end

      it "raises an exception" do
        app.should_receive(:call).never

        expect { subject.call(env) }.
          to raise_error(Vagrant::Errors::BoxOutdatedNoMetadata)
      end
    end

    context "with metadata URL" do
      let(:metadata_url) do
        Tempfile.new("vagrant").tap do |f|
          f.close
        end
      end

      let(:box_dir) { iso_env.box3("foo", "1.0", :virtualbox) }

      context "isn't outdated" do
        before do
          File.open(metadata_url.path, "w") do |f|
            f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "1.0",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{iso_env.box2_file(:virtualbox)}"
                }
              ]
            }
          ]
        }
            RAW
          end

          box = Vagrant::Box.new(
            "foo", :virtualbox, "1.0", box_dir,
            metadata_url: metadata_url.path)
          machine.stub(box: box)
        end

        it "marks it isn't outdated" do
          app.should_receive(:call).with(env)

          subject.call(env)

          expect(env[:box_outdated]).to be_false
        end

        it "talks to the UI" do
          env[:box_outdated_success_ui] = true

          app.should_receive(:call).with(env)
          env[:ui].should_receive(:success)

          subject.call(env)

          expect(env[:box_outdated]).to be_false
        end

        it "doesn't talk to UI if it is told" do
          app.should_receive(:call).with(env)
          env[:ui].should_receive(:success).never

          subject.call(env)

          expect(env[:box_outdated]).to be_false
        end
      end

      it "is outdated if it is" do
        File.open(metadata_url.path, "w") do |f|
          f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "1.0"
            },
            {
              "version": "1.5",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{iso_env.box2_file(:virtualbox)}"
                }
              ]
            }
          ]
        }
          RAW
        end

        box = Vagrant::Box.new(
          "foo", :virtualbox, "1.0", box_dir, metadata_url: metadata_url.path)
        machine.stub(box: box)

        subject.call(env)

        expect(env[:box_outdated]).to be_true
      end

      it "isn't outdated if the newer box is for another provider" do
        File.open(metadata_url.path, "w") do |f|
          f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "1.0"
            },
            {
              "version": "1.5",
              "providers": [
                {
                  "name": "vmware",
                  "url":  "#{iso_env.box2_file(:vmware)}"
                }
              ]
            }
          ]
        }
          RAW
        end

        box = Vagrant::Box.new(
          "foo", :virtualbox, "1.0", box_dir, metadata_url: metadata_url.path)
        machine.stub(box: box)

        subject.call(env)

        expect(env[:box_outdated]).to be_false
      end
    end
  end
end
