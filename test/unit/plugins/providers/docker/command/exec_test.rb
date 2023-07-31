# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/command/exec"

describe VagrantPlugins::DockerProvider::Command::Exec do
  include_context "unit"
  include_context "command plugin helpers"

  let(:env) { {
    action_runner: action_runner,
    machine: machine,
    ui: Vagrant::UI::Silent.new,
  } }

  subject { described_class.new(app, env) }
  let(:argv) { [] }

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

  subject { described_class.new(argv, env) }

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("templates/locales/providers_docker.yml")
    I18n.reload!
  end

  before do
    allow(Vagrant.plugin("2").manager).to receive(:commands).and_return({})
  end

  describe "#exec_command" do
    describe "with -t option" do
      let(:command) { ["/bin/bash"] }
      let(:options) { {pty: "true"} }

      it "calls Safe Exec" do
        allow(Kernel).to receive(:exec).and_return(true)
        expect(Vagrant::Util::SafeExec).to receive(:exec).with("docker", "exec", "-t", anything, "/bin/bash")
        subject.exec_command(machine, command, options)
      end
    end
    describe "without a command" do
      let(:argv) { [] }

      it "raises an error" do
        expect {
          subject.execute
        }.to raise_error(VagrantPlugins::DockerProvider::Errors::ExecCommandRequired)
      end
    end
  end
end
