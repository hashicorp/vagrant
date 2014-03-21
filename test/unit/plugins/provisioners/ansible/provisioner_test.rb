require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/ansible/provisioner")

describe VagrantPlugins::Ansible::Provisioner do
  include_context "unit"

  subject { described_class.new(machine, config) }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a Vagrant Environment
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:config)  { double("config") }

  let(:ssh_info) {{
    private_key_path: ['/path/to/my/key'],
    username: 'testuser'
  }}

  before do
    machine.stub(ssh_info: ssh_info)

    config.stub(playbook: 'playbook.yml')
    config.stub(extra_vars: nil)
    config.stub(inventory_path: nil)
    config.stub(ask_sudo_pass: nil)
    config.stub(limit: nil)
    config.stub(sudo: nil)
    config.stub(sudo_user: nil)
    config.stub(verbose: nil)
    config.stub(tags: nil)
    config.stub(skip_tags: nil)
    config.stub(start_at_task: nil)
    config.stub(groups: {})
    config.stub(host_key_checking: 'false')
    config.stub(raw_arguments: nil)
    config.stub(raw_ssh_args: nil)
  end

  shared_examples_for "an ansible-playbook subprocess" do
    it "sets default arguments" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|

        index = args.find_index("ansible-playbook")
        expect(index).to eql(0)
        index = args.find_index("--private-key=/path/to/my/key")
        expect(index).to eql(1)
        index = args.find_index("--user=testuser")
        expect(index).to eql(2)

        index = args.find_index("--limit=#{machine.name}")
        expect(index).to be > 0

        index = args.find_index("playbook.yml")
        expect(index).to eql(args.length-2)
      }
      subject.provision
    end

    it "exports default environment variables" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        cmd_opts = args.last
        expect(cmd_opts[:env]['ANSIBLE_FORCE_COLOR']).to eql("true")
        expect(cmd_opts[:env]['ANSIBLE_HOST_KEY_CHECKING']).to eql("false")
        expect(cmd_opts[:env]['PYTHONUNBUFFERED']).to eql(1)
      }
      subject.provision
    end
  end

  shared_examples_for "SSH transport mode is not forced" do
    it "does not export ANSIBLE_SSH_ARGS" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        cmd_opts = args.last
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to be_nil
      }
      subject.provision
    end
    it "does not force SSH transport mode" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        index = args.find_index("--connection=ssh")
        expect(index).to be_nil
      }
      subject.provision
    end
  end

  shared_examples_for "SSH transport mode is forced" do
    it "sets --connection=ssh argument" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        index = args.find_index("--connection=ssh")
        expect(index).to be > 0
      }
      subject.provision
    end
    it "enables ControlPersist (like Ansible defaults) via ANSIBLE_SSH_ARGS" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        cmd_opts = args.last
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ControlMaster=auto")
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ControlPersist=60s")
      }
      subject.provision
    end
  end

  describe "#provision" do

    let(:result) { Vagrant::Util::Subprocess::Result.new(0, "", "") }

    before do
      Vagrant::Util::Subprocess.stub(execute: result)
    end

    it "doesn't raise an error if it succeeds" do
      subject.provision
    end

    it "raises an error if the exit code is non-zero" do
      Vagrant::Util::Subprocess.stub(
        execute: Vagrant::Util::Subprocess::Result.new(1, "", ""))

      expect {subject.provision}.
        to raise_error(Vagrant::Errors::AnsibleFailed)
    end

    describe "with default options" do
      it_behaves_like 'an ansible-playbook subprocess'
      it_behaves_like 'SSH transport mode is not forced'

      it "generates the inventory" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          index = args.find_index("--inventory-file=#{File.join(machine.env.local_data_path, %w(provisioners ansible inventory vagrant_ansible_inventory))}")
          expect(index).to be > 0
        }
        subject.provision
      end
    end

    describe "with multiple SSH identities" do
      before do
        ssh_info[:private_key_path] = ['/path/to/my/key', '/an/other/identity', '/yet/an/other/key']
      end

      it_behaves_like 'an ansible-playbook subprocess'
      it_behaves_like 'SSH transport mode is forced'

      it "passes additional Identity Files via ANSIBLE_SSH_ARGS" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o IdentityFile=/an/other/identity")
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o IdentityFile=/yet/an/other/key")
        }
        subject.provision
      end
    end

    describe "with ssh forwarding enabled" do
      before do
        ssh_info[:forward_agent] = true
      end

      it_behaves_like 'an ansible-playbook subprocess'
      it_behaves_like 'SSH transport mode is forced'

      it "enables SSH-Forwarding via ANSIBLE_SSH_ARGS" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ForwardAgent=yes")
        }
        subject.provision
      end
    end

  end
end
