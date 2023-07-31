# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


shared_examples_for "Ansible setup via pip" do

  describe "when install_mode is :pip" do
    before { allow(communicator).to receive(:test) }

    it "installs pip and calls Cap::Guest::Pip::pip_install" do
      expect(communicator).to receive(:sudo).at_least(1).times.ordered
      expect(VagrantPlugins::Ansible::Cap::Guest::Pip).to receive(:pip_install).once.ordered.
        with(machine, "ansible", anything, anything, true)

      subject.ansible_install(machine, :pip, "", "", "")
    end
  end

  describe "when install_mode is :pip_args_only" do
    before { allow(communicator).to receive(:test) }

    it "installs pip and calls Cap::Guest::Pip::pip_install with 'pip_args' parameter" do
      pip_args = "-r /vagrant/requirements.txt"

      expect(communicator).to receive(:sudo).at_least(1).times.ordered
      expect(VagrantPlugins::Ansible::Cap::Guest::Pip).to receive(:pip_install).with(machine, "", "", pip_args, false).ordered

      subject.ansible_install(machine, :pip_args_only, "", pip_args, "")
    end
  end

end

shared_examples_for "Ansible setup via pip on Debian-based systems" do

  describe "installs required Debian packages and..." do
    before { allow(communicator).to receive(:test) }
    pip_install_cmd = "foo"

    it "calls Cap::Guest::Pip::get_pip with 'pip' install_mode" do
      expect(communicator).to receive(:sudo).
        with("apt-get update -y -qq")
      expect(communicator).to receive(:sudo).
        with("DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --option \"Dpkg::Options::=--force-confold\" build-essential curl git libssl-dev libffi-dev python-dev")
      expect(communicator).to receive(:sudo).
        with("pip install --upgrade ansible")

      subject.ansible_install(machine, :pip, "", "", pip_install_cmd)
    end

    it "calls Cap::Guest::Pip::get_pip with 'pip_args_only' install_mode" do
      expect(communicator).to receive(:sudo).
        with("apt-get update -y -qq")
      expect(communicator).to receive(:sudo).
        with("DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --option \"Dpkg::Options::=--force-confold\" build-essential curl git libssl-dev libffi-dev python-dev")
      expect(communicator).to receive(:sudo).
        with("pip install")

      subject.ansible_install(machine, :pip_args_only, "", "", pip_install_cmd)
    end

    context "when python-dev-is-python3 package is available" do
      before { allow(communicator).to receive(:test).with("apt-cache show python-dev-is-python3").and_return(true) }

      it "calls Cap::Guest::Pip::get_pip with 'pip' install_mode" do
        expect(communicator).to receive(:sudo).
          with("apt-get update -y -qq")
        expect(communicator).to receive(:sudo).
          with("DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --option \"Dpkg::Options::=--force-confold\" build-essential curl git libssl-dev libffi-dev python-dev-is-python3")
        expect(communicator).to receive(:sudo).
          with("pip install --upgrade ansible")

        subject.ansible_install(machine, :pip, "", "", pip_install_cmd)
      end

      it "calls Cap::Guest::Pip::get_pip with 'pip_args_only' install_mode" do
        expect(communicator).to receive(:sudo).
          with("apt-get update -y -qq")
        expect(communicator).to receive(:sudo).
          with("DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --option \"Dpkg::Options::=--force-confold\" build-essential curl git libssl-dev libffi-dev python-dev-is-python3")
        expect(communicator).to receive(:sudo).
          with("pip install")

        subject.ansible_install(machine, :pip_args_only, "", "", pip_install_cmd)
      end
    end

  end

  it_behaves_like "Ansible setup via pip"

end

shared_examples_for "Ansible setup via pip is not implemented" do

  describe "when install_mode is different from :default" do
    it "raises an AnsiblePipInstallIsNotSupported error" do
      expect { subject.ansible_install(machine, :ansible_the_hardway, "", "", "") }.to raise_error(VagrantPlugins::Ansible::Errors::AnsiblePipInstallIsNotSupported)
    end
  end

end
