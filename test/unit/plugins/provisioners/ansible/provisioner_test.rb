require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/ansible/config")
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
  let(:config)  { VagrantPlugins::Ansible::Config.new }
  let(:file_that_exists) { File.expand_path(__FILE__) }

  let(:ssh_info) {{
    private_key_path: ['/path/to/my/key'],
    username: 'testuser'
  }}

  before do
    machine.stub(ssh_info: ssh_info)

    config.playbook = 'playbook.yml'

    $generated_inventory_file = File.join(machine.env.local_data_path, %w(provisioners ansible inventory vagrant_ansible_inventory))
  end

  shared_examples_for "an ansible-playbook subprocess" do
    it "sets default arguments" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|

        expect(args[0]).to eq("ansible-playbook")
        expect(args[1]).to eq("--private-key=/path/to/my/key")
        expect(args[2]).to eq("--user=testuser")

        index = args.index("--limit=#{machine.name}")
        expect(index).to be > 0

        expect(args[args.length-2]).to eq("playbook.yml")
      }
    end

    it "exports default environment variables" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        cmd_opts = args.last
        expect(cmd_opts[:env]['ANSIBLE_FORCE_COLOR']).to eql("true")
        expect(cmd_opts[:env]['ANSIBLE_HOST_KEY_CHECKING']).to eql("false")
        expect(cmd_opts[:env]['PYTHONUNBUFFERED']).to eql(1)
      }
    end
  end

  shared_examples_for "SSH transport mode is not forced" do
    it "does not export ANSIBLE_SSH_ARGS" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        cmd_opts = args.last
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to be_nil
      }
    end
    it "does not force SSH transport mode" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        index = args.index("--connection=ssh")
        expect(index).to be_nil
      }
    end
  end

  shared_examples_for "SSH transport mode is forced" do
    it "sets --connection=ssh argument" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        index = args.index("--connection=ssh")
        expect(index).to be > 0
      }
    end
    it "enables ControlPersist (like Ansible defaults) via ANSIBLE_SSH_ARGS" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        cmd_opts = args.last
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ControlMaster=auto")
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ControlPersist=60s")
      }
    end
  end

  describe "#provision" do

    before do
      unless example.metadata[:skip_before]
        config.finalize!
        Vagrant::Util::Subprocess.stub(execute: Vagrant::Util::Subprocess::Result.new(0, "", ""))
      end
    end

    after do
      unless example.metadata[:skip_after]
        subject.provision
      end
    end

    it "doesn't raise an error if it succeeds" do
    end

    it "raises an error if the exit code is non-zero", skip_before: true, skip_after: true do
      config.finalize!
      Vagrant::Util::Subprocess.stub(execute: Vagrant::Util::Subprocess::Result.new(1, "", ""))

      expect {subject.provision}.to raise_error(Vagrant::Errors::AnsibleFailed)
    end

    describe "with default options" do

      it_behaves_like 'an ansible-playbook subprocess'
      it_behaves_like 'SSH transport mode is not forced'

      it "generates an inventory file and uses it" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(File.exists?($generated_inventory_file)).to be_true
          expect(args.include?("--inventory-file=#{$generated_inventory_file}")).to be_true
        }
      end
    end

    describe "with inventory_path option" do
      before do
        config.inventory_path = file_that_exists
      end

      it_behaves_like 'an ansible-playbook subprocess'
      it_behaves_like 'SSH transport mode is not forced'

      it "uses given inventory path" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args.include?("--inventory-file=#{file_that_exists}")).to be_true
          expect(args.include?("--inventory-file=#{$generated_inventory_file}")).to be_false
        }
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
      end
    end

  end
end
