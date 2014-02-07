require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::HandleBox do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:env) { {
    action_runner: action_runner,
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

  let(:action_runner) { double("action_runner") }
  let(:box) do
    box_dir = iso_env.box3("foo", "1.0", :virtualbox)
    Vagrant::Box.new("foo", :virtualbox, "1.0", box_dir)
  end
  let(:machine) { iso_vagrant_env.machine(iso_vagrant_env.machine_names[0], :dummy) }

  it "works if there is no box set" do
    machine.config.vm.box = nil
    machine.config.vm.box_url = nil

    app.should_receive(:call).with(env)

    subject.call(env)
  end

  it "doesn't do anything if a box exists" do
    machine.stub(box: box)

    action_runner.should_receive(:run).never
    app.should_receive(:call).with(env)

    subject.call(env)
  end

  context "with a box set and no box_url" do
    before do
      machine.stub(box: nil)

      machine.config.vm.box = "foo"
    end

    it "adds a box that doesn't exist" do
      action_runner.should_receive(:run).with do |action, opts|
        expect(opts[:box_name]).to eq(machine.config.vm.box)
        expect(opts[:box_url]).to eq(machine.config.vm.box)
        expect(opts[:box_provider]).to eq(:dummy)
        expect(opts[:box_version]).to eq(machine.config.vm.box_version)
        true
      end

      app.should_receive(:call).with(env)

      subject.call(env)
    end

    it "adds a box using any format the provider allows" do
      machine.provider_options[:box_format] = [:foo, :bar]

      action_runner.should_receive(:run).with do |action, opts|
        expect(opts[:box_name]).to eq(machine.config.vm.box)
        expect(opts[:box_url]).to eq(machine.config.vm.box)
        expect(opts[:box_provider]).to eq([:foo, :bar])
        expect(opts[:box_version]).to eq(machine.config.vm.box_version)
        true
      end

      app.should_receive(:call).with(env)

      subject.call(env)
    end
  end

  context "with a box and box_url set" do
    before do
      machine.stub(box: nil)

      machine.config.vm.box = "foo"
      machine.config.vm.box_url = "bar"
    end

    it "adds a box that doesn't exist" do
      action_runner.should_receive(:run).with do |action, opts|
        expect(opts[:box_name]).to eq(machine.config.vm.box)
        expect(opts[:box_url]).to eq(machine.config.vm.box_url)
        expect(opts[:box_provider]).to eq(:dummy)
        expect(opts[:box_version]).to eq(machine.config.vm.box_version)
        true
      end

      app.should_receive(:call).with(env)

      subject.call(env)
    end
  end
end
