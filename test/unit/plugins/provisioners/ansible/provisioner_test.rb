require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/ansible/config")
require Vagrant.source_root.join("plugins/provisioners/ansible/provisioner")

#
# Helper Functions
#

def find_last_argument_after(ref_index, ansible_playbook_args, arg_pattern)
  subset = ansible_playbook_args[(ref_index + 1)..(ansible_playbook_args.length-2)].reverse
  subset.each do |i|
    return true if i =~ arg_pattern
  end
  return false
end

describe VagrantPlugins::Ansible::Provisioner do
  include_context "unit"

  subject { described_class.new(machine, config) }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a Vagrant Environment to provide:
    # - a location for the generated inventory
    # - multi-machines configuration

    env = isolated_environment
    env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
  config.vm.define :machine1
  config.vm.define :machine2
end
VF
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:config)  { VagrantPlugins::Ansible::Config.new }
  let(:ssh_info) {{
    private_key_path: ['/path/to/my/key'],
    username: 'testuser',
    host: '127.0.0.1',
    port: 2223
  }}

  let(:existing_file) { File.expand_path(__FILE__) }
  let(:generated_inventory_dir) { File.join(machine.env.local_data_path, %w(provisioners ansible inventory)) }
  let(:generated_inventory_file) { File.join(generated_inventory_dir, 'vagrant_ansible_inventory') }

  before do
    Vagrant::Util::Platform.stub(solaris?: false)

    machine.stub(ssh_info: ssh_info)
    machine.env.stub(active_machines: [[iso_env.machine_names[0], :dummy], [iso_env.machine_names[1], :dummy]])

    stubbed_ui = Vagrant::UI::Colored.new
    stubbed_ui.stub(detail: "")
    machine.env.stub(ui: stubbed_ui)

    config.playbook = 'playbook.yml'
  end

  #
  # Class methods for code reuse across examples
  #

  def self.it_should_set_arguments_and_environment_variables(
    expected_args_count = 6, expected_vars_count = 4, expected_host_key_checking = false, expected_transport_mode = "ssh")

    it "sets implicit arguments in a specific order" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|

        expect(args[0]).to eq("ansible-playbook")
        expect(args[1]).to eq("--user=#{machine.ssh_info[:username]}")
        expect(args[2]).to eq("--connection=ssh")
        expect(args[3]).to eq("--timeout=30")

        inventory_count = args.count { |x| x =~ /^--inventory-file=.+$/ }
        expect(inventory_count).to be > 0

        expect(args[args.length-2]).to eq("playbook.yml")
      }
    end

    it "sets --limit argument" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        all_limits = args.select { |x| x =~ /^(--limit=|-l)/ }
        if config.raw_arguments
          raw_limits = config.raw_arguments.select { |x| x =~ /^(--limit=|-l)/ }
          expect(all_limits.length - raw_limits.length).to eq(1)
          expect(all_limits.last).to eq(raw_limits.last)
        else
          if config.limit
            limit = config.limit.kind_of?(Array) ? config.limit.join(',') : config.limit
            expect(all_limits.last).to eq("--limit=#{limit}")
          else
            expect(all_limits.first).to eq("--limit=#{machine.name}")
          end
        end
      }
    end

    it "exports environment variables" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        cmd_opts = args.last

        if expected_host_key_checking
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to_not include("-o UserKnownHostsFile=/dev/null")
        else
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o UserKnownHostsFile=/dev/null")
        end
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o IdentitiesOnly=yes")
        expect(cmd_opts[:env]['ANSIBLE_FORCE_COLOR']).to eql("true")
        expect(cmd_opts[:env]).to_not include("ANSIBLE_NOCOLOR")
        expect(cmd_opts[:env]['ANSIBLE_HOST_KEY_CHECKING']).to eql(expected_host_key_checking.to_s)
        expect(cmd_opts[:env]['PYTHONUNBUFFERED']).to eql(1)
      }
    end

    # "roughly" verify that only expected args/vars have been defined by the provisioner
    it "sets the expected number of arguments and environment variables" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        expect(args.length-2).to eq(expected_args_count)
        expect(args.last[:env].length).to eq(expected_vars_count)
      }
    end

    it "enables '#{expected_transport_mode}' transport mode" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        index = args.rindex("--connection=#{expected_transport_mode}")
        expect(index).to be > 0
        expect(find_last_argument_after(index, args, /--connection=\w+/)).to be_false
      }
    end

  end

  def self.it_should_set_optional_arguments(arg_map)
    it "sets optional arguments" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        arg_map.each_pair do |vagrant_option, ansible_argument|
          index = args.index(ansible_argument)
          if config.send(vagrant_option)
            expect(index).to be > 0
          else
            expect(index).to be_nil
          end
        end
      }
    end
  end

  def self.it_should_explicitly_enable_ansible_ssh_control_persist_defaults
    it "configures ControlPersist (like Ansible defaults) via ANSIBLE_SSH_ARGS" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        cmd_opts = args.last
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ControlMaster=auto")
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ControlPersist=60s")
      }
    end
  end

  def self.it_should_create_and_use_generated_inventory
    it "generates an inventory with all active machines" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        expect(config.inventory_path).to be_nil
        expect(File.exists?(generated_inventory_file)).to be_true
        inventory_content = File.read(generated_inventory_file)
        expect(inventory_content).to include("#{machine.name} ansible_ssh_host=#{machine.ssh_info[:host]} ansible_ssh_port=#{machine.ssh_info[:port]} ansible_ssh_private_key_file=#{machine.ssh_info[:private_key_path][0]}\n")
        expect(inventory_content).to include("# MISSING: '#{iso_env.machine_names[1]}' machine was probably removed without using Vagrant. This machine should be recreated.\n")
      }
    end

    it "sets as ansible inventory the directory containing the auto-generated inventory file" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        inventory_index = args.rindex("--inventory-file=#{generated_inventory_dir}")
        expect(inventory_index).to be > 0
        expect(find_last_argument_after(inventory_index, args, /--inventory-file=\w+/)).to be_false
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

    describe 'when ansible-playbook fails' do
      it "raises an error", skip_before: true, skip_after: true do
        config.finalize!
        Vagrant::Util::Subprocess.stub(execute: Vagrant::Util::Subprocess::Result.new(1, "", ""))

        expect {subject.provision}.to raise_error(Vagrant::Errors::AnsibleFailed)
      end
    end

    describe "with default options" do
      it_should_set_arguments_and_environment_variables
      it_should_create_and_use_generated_inventory

      it "does not add any group section to the generated inventory" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          inventory_content = File.read(generated_inventory_file)
          expect(inventory_content).to_not match(/^\s*\[^\\+\]\s*$/)

          # Note:
          # The expectation below is a workaround to a possible misuse (or bug) in RSpec/Ruby stack.
          # If 'args' variable is not required by in this block, the "Vagrant::Util::Subprocess).to receive"
          # surprisingly expects to receive "no args".
          # This problem can be "solved" by using args the "unnecessary" (but harmless) expectation below:
          expect(args.length).to be > 0
        }
      end

      it "does not show the ansible-playbook command" do
        expect(machine.env.ui).not_to receive(:detail).with { |full_command|
          expect(full_command).to include("ansible-playbook")
        }
      end
    end

    describe "with groups option" do
      it_should_create_and_use_generated_inventory

      it "adds group sections to the generated inventory" do
        config.groups = {
          "group1" => "#{machine.name}",
          "group1:children" => 'bar',
          "group2" => [iso_env.machine_names[1]],
          "group3" => ["unknown", "#{machine.name}"],
          "bar" => ["#{machine.name}", "group3"],
          "bar:children" => ["group1", "group2", "group3", "group4"],
          "bar:vars" => ["myvar=foo"],
        }

        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          inventory_content = File.read(generated_inventory_file)

          # Group variables are intentionally not supported in generated inventory
          expect(inventory_content).not_to match(/^\[.*:vars\]$/)

          # Accept String instead of Array for group that contains a single item
          expect(inventory_content).to include("[group1]\n#{machine.name}\n")
          expect(inventory_content).to include("[group1:children]\nbar\n")

          # Skip "lost" machines
          expect(inventory_content).to include("[group2]\n\n")

          # Skip "unknown" machines
          expect(inventory_content).to include("[group3]\n#{machine.name}\n")

          # Don't mix group names and host names
          expect(inventory_content).to include("[bar]\n#{machine.name}\n")

          # A group of groups only includes declared groups
          expect(inventory_content).not_to match(/^group4$/)
          expect(inventory_content).to include("[bar:children]\ngroup1\ngroup2\ngroup3\n")
        }
      end
    end

    describe "with host_key_checking option enabled" do
      before do
        config.host_key_checking = true
      end

      it_should_set_arguments_and_environment_variables 6, 4, true
    end

    describe "with boolean (flag) options disabled" do
      before do
        config.sudo = false
        config.ask_sudo_pass = false
        config.ask_vault_pass = false

        config.sudo_user = 'root'
      end

      it_should_set_arguments_and_environment_variables 7
      it_should_set_optional_arguments({ "sudo_user" => "--sudo-user=root" })

      it "it does not set boolean flag when corresponding option is set to false" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args.index("--sudo")).to be_nil
          expect(args.index("--ask-sudo-pass")).to be_nil
          expect(args.index("--ask-vault-pass")).to be_nil
        }
      end
    end

    describe "with raw_arguments option" do
      before do
        config.sudo = false
        config.skip_tags = %w(foo bar)
        config.limit = "all"
        config.raw_arguments = ["--connection=paramiko",
                                "--skip-tags=ignored",
                                "--module-path=/other/modules",
                                "--sudo",
                                "-l localhost",
                                "--limit=foo",
                                "--limit=bar",
                                "--inventory-file=/forget/it/my/friend",
                                "--user=lion",
                                "--new-arg=yeah"]
      end

      it_should_set_arguments_and_environment_variables 17, 4, false, "paramiko"

      it "sets all raw arguments" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          config.raw_arguments.each do |raw_arg|
            expect(args).to include(raw_arg)
          end
        }
      end

      it "sets raw arguments after arguments related to supported options" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args.index("--user=lion")).to be > args.index("--user=testuser")
          expect(args.index("--inventory-file=/forget/it/my/friend")).to be > args.index("--inventory-file=#{generated_inventory_dir}")
          expect(args.index("--limit=bar")).to be > args.index("--limit=all")
          expect(args.index("--skip-tags=ignored")).to be > args.index("--skip-tags=foo,bar")
        }
      end

      it "sets boolean flag (e.g. --sudo) defined in raw_arguments, even if corresponding option is set to false" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args).to include('--sudo')
        }
      end

    end

    describe "with limit option" do
      before do
        config.limit = %w(foo !bar)
      end

      it_should_set_arguments_and_environment_variables
    end

    describe "with inventory_path option" do
      before do
        config.inventory_path = existing_file
      end

      it_should_set_arguments_and_environment_variables

      it "does not generate the inventory and uses given inventory path instead" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args).to include("--inventory-file=#{existing_file}")
          expect(args).not_to include("--inventory-file=#{generated_inventory_file}")
          expect(File.exists?(generated_inventory_file)).to be_false
        }
      end
    end

    describe "with ask_vault_pass option" do
      before do
        config.ask_vault_pass = true
      end

      it_should_set_arguments_and_environment_variables 7

      it "should ask the vault password" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args).to include("--ask-vault-pass")
        }
      end
    end

    describe "with vault_password_file option" do
      before do
        config.vault_password_file = existing_file
      end

      it_should_set_arguments_and_environment_variables 7

      it "uses the given vault password file" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args).to include("--vault-password-file=#{existing_file}")
        }
      end
    end

    describe "with raw_ssh_args" do
      before do
        config.raw_ssh_args = ['-o ControlMaster=no', '-o ForwardAgent=no']
      end

      it_should_set_arguments_and_environment_variables 6, 4
      it_should_explicitly_enable_ansible_ssh_control_persist_defaults

      it "passes custom SSH options via ANSIBLE_SSH_ARGS with the highest priority" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          cmd_opts = args.last
          raw_opt_index = cmd_opts[:env]['ANSIBLE_SSH_ARGS'].index("-o ControlMaster=no")
          default_opt_index = cmd_opts[:env]['ANSIBLE_SSH_ARGS'].index("-o ControlMaster=auto")
          expect(raw_opt_index).to be < default_opt_index
        }
      end

      describe "and with ssh forwarding enabled" do
        before do
          ssh_info[:forward_agent] = true
        end

        it "sets '-o ForwardAgent=yes' via ANSIBLE_SSH_ARGS with higher priority than raw_ssh_args values" do
          expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
            cmd_opts = args.last
            forwardAgentYes = cmd_opts[:env]['ANSIBLE_SSH_ARGS'].index("-o ForwardAgent=yes")
            forwardAgentNo = cmd_opts[:env]['ANSIBLE_SSH_ARGS'].index("-o ForwardAgent=no")
            expect(forwardAgentYes).to be < forwardAgentNo
          }
        end
      end

    end

    describe "with multiple SSH identities" do
      before do
        ssh_info[:private_key_path] = ['/path/to/my/key', '/an/other/identity', '/yet/an/other/key']
      end

      it_should_set_arguments_and_environment_variables 6, 4
      it_should_explicitly_enable_ansible_ssh_control_persist_defaults

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

      it_should_set_arguments_and_environment_variables 6, 4
      it_should_explicitly_enable_ansible_ssh_control_persist_defaults

      it "enables SSH-Forwarding via ANSIBLE_SSH_ARGS" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ForwardAgent=yes")
        }
      end
    end

    describe "with verbose option" do
      before do
        config.verbose = 'v'
      end

      it_should_set_arguments_and_environment_variables 7
      it_should_set_optional_arguments({ "verbose" => "-v" })

      it "shows the ansible-playbook command" do
        expect(machine.env.ui).to receive(:detail).with { |full_command|
          expect(full_command).to eq("PYTHONUNBUFFERED=1 ANSIBLE_HOST_KEY_CHECKING=false ANSIBLE_FORCE_COLOR=true ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s' ansible-playbook --user=testuser --connection=ssh --timeout=30 --limit='machine1' --inventory-file=#{generated_inventory_dir} -v playbook.yml")
        }
      end
    end

    describe "without colorized output" do
      before do
        machine.env.stub(ui: Vagrant::UI::Basic.new)
      end

      it "disables ansible-playbook colored output" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]).to_not include("ANSIBLE_FORCE_COLOR")
          expect(cmd_opts[:env]['ANSIBLE_NOCOLOR']).to eql("true")
        }
      end
    end

    # Note:
    # The Vagrant Ansible provisioner does not validate the coherency of argument combinations,
    # and let ansible-playbook complain.
    describe "with a maximum of options" do
      before do
        # vagrant general options
        ssh_info[:forward_agent] = true
        ssh_info[:private_key_path] = ['/my/key1', '/my/key2']

        # command line arguments
        config.extra_vars = "@#{existing_file}"
        config.sudo = true
        config.sudo_user = 'deployer'
        config.verbose = "vvv"
        config.ask_sudo_pass = true
        config.ask_vault_pass = true
        config.vault_password_file = existing_file
        config.tags = %w(db www)
        config.skip_tags = %w(foo bar)
        config.limit = 'machine*:&vagrant:!that_one'
        config.start_at_task = 'an awesome task'
        config.raw_arguments = ["--why-not", "--su-user=foot", "--ask-su-pass", "--limit=all", "--private-key=./myself.key"]

        # environment variables
        config.host_key_checking = true
        config.raw_ssh_args = ['-o ControlMaster=no']
      end

      it_should_set_arguments_and_environment_variables 21, 4, true
      it_should_explicitly_enable_ansible_ssh_control_persist_defaults
      it_should_set_optional_arguments({  "extra_vars"          => "--extra-vars=@#{File.expand_path(__FILE__)}",
                                          "sudo"                => "--sudo",
                                          "sudo_user"           => "--sudo-user=deployer",
                                          "verbose"             => "-vvv",
                                          "ask_sudo_pass"       => "--ask-sudo-pass",
                                          "ask_vault_pass"      => "--ask-vault-pass",
                                          "vault_password_file" => "--vault-password-file=#{File.expand_path(__FILE__)}",
                                          "tags"                => "--tags=db,www",
                                          "skip_tags"           => "--skip-tags=foo,bar",
                                          "limit"               => "--limit=machine*:&vagrant:!that_one",
                                          "start_at_task"       => "--start-at-task=an awesome task",
                                        })

      it "also includes given raw arguments" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args).to include("--why-not")
          expect(args).to include("--su-user=foot")
          expect(args).to include("--ask-su-pass")
          expect(args).to include("--limit=all")
          expect(args).to include("--private-key=./myself.key")
        }
      end

      it "shows the ansible-playbook command, with additional quotes when required" do
        expect(machine.env.ui).to receive(:detail).with { |full_command|
          expect(full_command).to eq("PYTHONUNBUFFERED=1 ANSIBLE_HOST_KEY_CHECKING=true ANSIBLE_FORCE_COLOR=true ANSIBLE_SSH_ARGS='-o IdentitiesOnly=yes -o IdentityFile=/my/key1 -o IdentityFile=/my/key2 -o ForwardAgent=yes -o ControlMaster=no -o ControlMaster=auto -o ControlPersist=60s' ansible-playbook --user=testuser --connection=ssh --timeout=30 --limit='machine*:&vagrant:!that_one' --inventory-file=#{generated_inventory_dir} --extra-vars=@#{File.expand_path(__FILE__)} --sudo --sudo-user=deployer -vvv --ask-sudo-pass --ask-vault-pass --vault-password-file=#{File.expand_path(__FILE__)} --tags=db,www --skip-tags=foo,bar --start-at-task='an awesome task' --why-not --su-user=foot --ask-su-pass --limit='all' --private-key=./myself.key playbook.yml")
        }
      end
    end

    #
    # Special cases related to the VM provider context
    #

    context "with Docker provider on a non-Linux host" do

      let(:fake_host_ssh_info) {{
        private_key_path: ['/path/to/docker/host/key'],
        username: 'boot9docker',
        host: '127.0.0.1',
        port: 2299
      }}
      let(:fake_host_vm) {
        double("host_vm").tap do |h|
          h.stub(ssh_info: fake_host_ssh_info)
        end
      }

      before do
        machine.stub(provider_name: :docker)
        machine.provider.stub(host_vm?: true)
        machine.provider.stub(host_vm: fake_host_vm)
      end

      it "uses an SSH ProxyCommand to reach the VM" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ProxyCommand='ssh boot9docker@127.0.0.1 -p 2299 -i /path/to/docker/host/key -o Compression=yes -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no exec nc %h %p 2>/dev/null'")
        }
      end
    end

    #
    # Special cases related to the Vagrant Host operating system in use
    #

    context "with a Solaris-like host" do
      before do
        Vagrant::Util::Platform.stub(solaris?: true)
      end

      it "does not set IdentitiesOnly=yes in ANSIBLE_SSH_ARGS" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to_not include("-o IdentitiesOnly=yes")

          # Note:
          # The expectation below is a workaround to a possible misuse (or bug) in RSpec/Ruby stack.
          # If 'args' variable is not required by in this block, the "Vagrant::Util::Subprocess).to receive"
          # surprisingly expects to receive "no args".
          # This problem can be "solved" by using args the "unnecessary" (but harmless) expectation below:
          expect(true).to be_true
        }
      end

      describe "and with host_key_checking option enabled" do
        it "does not set ANSIBLE_SSH_ARGS environment variable" do
          config.host_key_checking = true

          expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
            cmd_opts = args.last
            expect(cmd_opts[:env]).to_not include('ANSIBLE_SSH_ARGS')

            # Note:
            # The expectation below is a workaround to a possible misuse (or bug) in RSpec/Ruby stack.
            # If 'args' variable is not required by in this block, the "Vagrant::Util::Subprocess).to receive"
            # surprisingly expects to receive "no args".
            # This problem can be "solved" by using args the "unnecessary" (but harmless) expectation below:
            expect(true).to be_true
          }
        end
      end

    end
  end
end
