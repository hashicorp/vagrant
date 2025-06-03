# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/create"

describe VagrantPlugins::DockerProvider::Action::Create do
  include_context "unit"
  include_context "virtualbox"

  let(:sandbox) { isolated_environment }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    sandbox.vagrantfile("")
    sandbox.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :virtualbox).tap do |m|
      allow(m.provider).to receive(:driver).and_return(driver)
    end
  end

  let(:env)    {{ machine: machine, ui: machine.ui, root_path: Pathname.new(".") }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver", create: "abcd1234") }

  subject { described_class.new(app, env) }

  after do
    sandbox.close
  end

  describe "#call" do
    it "calls the next action in the chain" do
      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)
      action.call(env)

      expect(called).to eq(true)
    end
  end

  describe "#forwarded_ports" do
    it "does not clobber ports with different protocols" do
      subject.instance_variable_set(:@machine, machine)
      machine.config.vm.network "forwarded_port", guest: 8125, host: 8125, protocol: "tcp"
      machine.config.vm.network "forwarded_port", guest: 8125, host: 8125, protocol: "udp"

      result = subject.forwarded_ports(false)

      expect(result).to eq(["8125:8125", "8125:8125/udp"])
    end
  end

  describe "#generate_container_name" do
    let(:env) {{root_path: root_path}}
    let(:root_path) {Pathname.new("/path/to/root")}

    before do
      subject.instance_variable_set(:@env, env)
      subject.instance_variable_set(:@machine, machine)
    end

    it "should not remove any characters" do
      expect(subject.generate_container_name).to start_with("root")
    end

    context "when root path starts with underscores" do
      let(:root_path) {Pathname.new("/path/to/__root")}
      it "should remove underscores" do
        expect(subject.generate_container_name).to start_with("root")
      end
    end

    context "when root path starts with dashes" do
      let(:root_path) {Pathname.new("/path/to/--root")}
      it "should remove dashes" do
        expect(subject.generate_container_name).to start_with("root")
      end
    end

    context "when root path starts with combination of invalid starting characters" do
      let(:root_path) {Pathname.new("/path/to/_.-_-root")}
      it "should remove invalid starting characters" do
        expect(subject.generate_container_name).to start_with("root")
      end
    end

    context "when root path ends with underscores" do
      let(:root_path) {Pathname.new("/path/to/root__")}
      it "should not remove trailing underscroes" do
        expect(subject.generate_container_name).to start_with("root_")
      end
    end

    context "when root path ends with invalid characters" do
      let(:root_path) {Pathname.new("/path/to/root_.")}
      it "should remove invalid trailing characters" do
        expect(subject.generate_container_name).to start_with("root_")
      end
    end

    context "when root path contains invalid characters" do
      let(:root_path) {Pathname.new("/path/to/root-.path_.")}
      it "should only remove invalid characters" do
        expect(subject.generate_container_name).to start_with("root-path_")
      end
    end

  end

end
