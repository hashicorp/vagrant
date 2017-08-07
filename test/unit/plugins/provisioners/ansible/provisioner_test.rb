require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/ansible/config/host")
require Vagrant.source_root.join("plugins/provisioners/ansible/provisioner/host")

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

describe VagrantPlugins::Ansible::Provisioner::Host do
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
  let(:config)  { VagrantPlugins::Ansible::Config::Host.new }
  let(:ssh_info) {{
    private_key_path: ['/path/to/my/key'],
    keys_only: true,
    username: 'testuser',
    host: '127.0.0.1',
    port: 2223
  }}
  let(:default_execute_result) { Vagrant::Util::Subprocess::Result.new(0, "", "") }

  let(:existing_file) { File.expand_path(__FILE__) }
  let(:generated_inventory_dir) { File.join(machine.env.local_data_path, %w(provisioners ansible inventory)) }
  let(:generated_inventory_file) { File.join(generated_inventory_dir, 'vagrant_ansible_inventory') }

  before do
    allow(Vagrant::Util::Platform).to receive(:solaris?).and_return(false)

    allow(machine).to receive(:ssh_info).and_return(ssh_info)
    allow(machine.env).to receive(:active_machines)
      .and_return([[iso_env.machine_names[0], :dummy], [iso_env.machine_names[1], :dummy]])

    stubbed_ui = Vagrant::UI::Colored.new
    allow(stubbed_ui).to receive(:detail).and_return("")
    allow(machine.env).to receive(:ui).and_return(stubbed_ui)

    config.playbook = 'playbook.yml'
  end

  #
  # Class methods for code reuse across examples
  #

  def self.it_should_set_arguments_and_environment_variables(
    expected_args_count = 5,
    expected_vars_count = 4,
    expected_host_key_checking = false,
    expected_transport_mode = "ssh")

    it "sets implicit arguments in a specific order" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|

        expect(args[0]).to eq("ansible-playbook")
        expect(args[1]).to eq("--connection=ssh")
        expect(args[2]).to eq("--timeout=30")

        inventory_count = args.count { |x| x =~ /^--inventory-file=.+$/ }
        expect(inventory_count).to be > 0

        expect(args[args.length-2]).to eq("playbook.yml")
      }.and_return(default_execute_result)
    end

    it "sets --limit argument" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
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
      }.and_return(default_execute_result)
    end

    it "exports environment variables" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
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
      }.and_return(default_execute_result)
    end

    # "roughly" verify that only expected args/vars have been defined by the provisioner
    it "sets the expected number of arguments and environment variables" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        expect(args.length-2).to eq(expected_args_count)
        expect(args.last[:env].length).to eq(expected_vars_count)
      }.and_return(default_execute_result)
    end

    it "enables '#{expected_transport_mode}' as default transport mode" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        index = args.rindex("--connection=#{expected_transport_mode}")
        expect(index).to be > 0
        expect(find_last_argument_after(index, args, /--connection=\w+/)).to be(false)
      }.and_return(default_execute_result)
    end

  end

  def self.it_should_set_optional_arguments(arg_map)
    it "sets optional arguments" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        arg_map.each_pair do |vagrant_option, ansible_argument|
          index = args.index(ansible_argument)
          if config.send(vagrant_option)
            expect(index).to be > 0
          else
            expect(index).to be_nil
          end
        end
      }.and_return(default_execute_result)
    end
  end

  def self.it_should_explicitly_enable_ansible_ssh_control_persist_defaults
    it "configures ControlPersist (like Ansible defaults) via ANSIBLE_SSH_ARGS" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        cmd_opts = args.last
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ControlMaster=auto")
        expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ControlPersist=60s")
      }.and_return(default_execute_result)
    end
  end

  def self.it_should_create_and_use_generated_inventory(with_ssh_user = true)
    it "generates an inventory with all active machines" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        expect(config.inventory_path).to be_nil
        expect(File.exists?(generated_inventory_file)).to be(true)
        inventory_content = File.read(generated_inventory_file)
        if with_ssh_user
          expect(inventory_content).to include("#{machine.name} ansible_ssh_host=#{machine.ssh_info[:host]} ansible_ssh_port=#{machine.ssh_info[:port]} ansible_ssh_user='#{machine.ssh_info[:username]}' ansible_ssh_private_key_file='#{machine.ssh_info[:private_key_path][0]}'\n")
        else
          expect(inventory_content).to include("#{machine.name} ansible_ssh_host=#{machine.ssh_info[:host]} ansible_ssh_port=#{machine.ssh_info[:port]} ansible_ssh_private_key_file='#{machine.ssh_info[:private_key_path][0]}'\n")
        end
        expect(inventory_content).to include("# MISSING: '#{iso_env.machine_names[1]}' machine was probably removed without using Vagrant. This machine should be recreated.\n")
      }.and_return(default_execute_result)
    end

    it "sets as ansible inventory the directory containing the auto-generated inventory file" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        inventory_index = args.rindex("--inventory-file=#{generated_inventory_dir}")
        expect(inventory_index).to be > 0
        expect(find_last_argument_after(inventory_index, args, /--inventory-file=\w+/)).to be(false)
      }.and_return(default_execute_result)
    end
  end

  describe "#provision" do

    before do
      unless RSpec.current_example.metadata[:skip_before]
        config.finalize!

        allow(Vagrant::Util::Subprocess).to receive(:execute)
          .and_return(Vagrant::Util::Subprocess::Result.new(0, "", ""))
        allow(subject).to receive(:check_path)
      end
    end

    after do
      unless RSpec.current_example.metadata[:skip_after]
        subject.provision
      end
    end

    describe 'checking existence of Ansible configuration files' do

      STUBBED_INVALID_PATH = "/test/239nfmd/invalid_path".freeze

      it 'raises an error when the `playbook` file does not exist', skip_before: true, skip_after: true do
        allow(subject).to receive(:check_path).and_raise(VagrantPlugins::Ansible::Errors::AnsibleError,
          _key: :config_file_not_found,
          config_option: "playbook",
          path: STUBBED_INVALID_PATH,
          system: "host")

        config.playbook = STUBBED_INVALID_PATH
        config.finalize!

        expect {subject.provision}.to raise_error(VagrantPlugins::Ansible::Errors::AnsibleError,
          "`playbook` does not exist on the host: #{STUBBED_INVALID_PATH}")
      end

      %w(config_file extra_vars inventory_path galaxy_role_file vault_password_file).each do |option_name|
        it "raises an error when the '#{option_name}' does not exist", skip_before: true, skip_after: true do
          allow(Vagrant::Util::Subprocess).to receive(:execute)
            .and_return( Vagrant::Util::Subprocess::Result.new(0, "", ""))

            config.playbook = existing_file
            config.send(option_name + '=', STUBBED_INVALID_PATH)
            if option_name == 'extra_vars'
              # little trick to auto-append the '@' prefix, which is a duty of the config validator...
              config.validate(machine)
            end
            config.finalize!

            expect {subject.provision}.to raise_error(VagrantPlugins::Ansible::Errors::AnsibleError,
              "`#{option_name}` does not exist on the host: #{STUBBED_INVALID_PATH}")
        end
      end

    end

    describe 'when ansible-playbook fails' do
      it "raises an error", skip_before: true, skip_after: true do
        config.finalize!

        allow(subject).to receive(:check_path)
        allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(Vagrant::Util::Subprocess::Result.new(1, "", ""))

        expect {subject.provision}.to raise_error(VagrantPlugins::Ansible::Errors::AnsibleCommandFailed)
      end
    end

    describe "with default options" do
      it_should_set_arguments_and_environment_variables
      it_should_create_and_use_generated_inventory

      it "does not add any group section to the generated inventory" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          inventory_content = File.read(generated_inventory_file)
          expect(inventory_content).to_not match(/^\s*\[^\\+\]\s*$/)
        }.and_return(default_execute_result)
      end

      it "doesn't show the ansible-playbook command" do
        expect(machine.env.ui).not_to receive(:detail).with(any_args) { |full_command|
          expect(full_command).to include("ansible-playbook")
        }
      end
    end

    describe "with playbook_command option" do
      before do
        config.playbook_command = "custom-ansible-playbook"
      end

      it "uses custom playbook_command to run playbooks" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args[0]).to eq("custom-ansible-playbook")
        }.and_return(default_execute_result)
      end
    end

    describe "with host_vars option" do
      it_should_create_and_use_generated_inventory

      it "adds host variables (given in Hash format) to the generated inventory" do
        config.host_vars = {
          machine1: {"http_port" => 80, "comments" => "'some text with spaces'"}
        }
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          inventory_content = File.read(generated_inventory_file)
          expect(inventory_content).to match("^" + Regexp.quote(machine.name) + ".+http_port=80 comments='some text with spaces'$")
        }.and_return(default_execute_result)
      end

      it "adds host variables (given in Array format) to the generated inventory" do
        config.host_vars = {
          machine1: ["http_port=80", "maxRequestsPerChild=808"]
        }
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          inventory_content = File.read(generated_inventory_file)
          expect(inventory_content).to match("^" + Regexp.quote(machine.name) + ".+http_port=80 maxRequestsPerChild=808")
        }.and_return(default_execute_result)
      end

      it "adds host variables (given in String format) to the generated inventory " do
        config.host_vars = {
          :machine1 => "http_port=80 maxRequestsPerChild=808"
        }
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          inventory_content = File.read(generated_inventory_file)
          expect(inventory_content).to match("^" + Regexp.quote(machine.name) + ".+http_port=80 maxRequestsPerChild=808")
        }.and_return(default_execute_result)
      end

      it "retrieves the host variables by machine name, also in String format" do
        config.host_vars = {
          "machine1" => "http_port=80 maxRequestsPerChild=808"
        }
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          inventory_content = File.read(generated_inventory_file)
          expect(inventory_content).to match("^" + Regexp.quote(machine.name) + ".+http_port=80 maxRequestsPerChild=808")
        }.and_return(default_execute_result)
      end
    end

    describe "with groups option" do
      it_should_create_and_use_generated_inventory

      it "adds group sections to the generated inventory" do
        config.groups = {
          "group1" => "machine1",
          "group1:children" => 'bar group3',
          "group2" => [iso_env.machine_names[1]],
          "group3" => ["unknown", "#{machine.name}"],
          "group4" => ["machine[1:2]", "machine[a:f]"],
          "group6" => [machine.name],
          "bar" => ["#{machine.name}", "group3"],
          "bar:children" => ["group1", "group2", "group3", "group5"],
        }

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          inventory_content = File.read(generated_inventory_file)

          # Accept String instead of Array for group member list
          expect(inventory_content).to include("[group1]\nmachine1\n\n")
          expect(inventory_content).to include("[group1:children]\nbar\ngroup3\n\n")

          # Skip "lost" machines
          expect(inventory_content).to include("[group2]\n\n")

          # Skip "unknown" machines
          expect(inventory_content).to include("[group3]\n#{machine.name}\n\n")

          # Accept Symbol datatype for group names
          expect(inventory_content).to include("[group6]\n#{machine.name}\n\n")

          # Accept host range patterns
          expect(inventory_content).to include("[group4]\nmachine[1:2]\nmachine[a:f]\n")

          # Don't mix group names and host names
          expect(inventory_content).to include("[bar]\n#{machine.name}\n\n")

          # A group of groups only includes declared groups
          expect(inventory_content).not_to include("group5")
          expect(inventory_content).to match(Regexp.quote("[bar:children]\ngroup1\ngroup2\ngroup3\n") + "$")
        }.and_return(default_execute_result)
      end

      it "adds group vars to the generated inventory" do
        config.groups = {
          "group1" => [machine.name],
          "group2" => [machine.name],
          "group3" => [machine.name],
          "group1:vars" => {"hashvar1" => "hashvalue1", "hashvar2" => "hashvalue2"},
          "group2:vars" => ["arrayvar1=arrayvalue1", "arrayvar2=arrayvalue2"],
          "group3:vars" => "stringvar1=stringvalue1 stringvar2=stringvalue2",
        }

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          inventory_content = File.read(generated_inventory_file)

          # Hash syntax
          expect(inventory_content).to include("[group1:vars]\nhashvar1=hashvalue1\nhashvar2=hashvalue2\n")

          # Array syntax
          expect(inventory_content).to include("[group2:vars]\narrayvar1=arrayvalue1\narrayvar2=arrayvalue2\n")

          # Single string syntax
          expect(inventory_content).to include("[group3:vars]\nstringvar1=stringvalue1\nstringvar2=stringvalue2\n")
        }.and_return(default_execute_result)
      end
    end

    describe "with host_key_checking option enabled" do
      before do
        config.host_key_checking = true
      end

      it_should_set_arguments_and_environment_variables 5, 4, true
    end

    describe "with boolean (flag) options disabled" do
      before do
        config.sudo = false
        config.ask_sudo_pass = false
        config.ask_vault_pass = false

        config.sudo_user = 'root'
      end

      it_should_set_arguments_and_environment_variables 6
      it_should_set_optional_arguments({ "sudo_user" => "--sudo-user=root" })

      it "it does not set boolean flag when corresponding option is set to false" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args.index("--sudo")).to be_nil
          expect(args.index("--ask-sudo-pass")).to be_nil
          expect(args.index("--ask-vault-pass")).to be_nil
        }.and_return(default_execute_result)
      end
    end

    describe "with raw_arguments option" do
      before do
        config.sudo = false
        config.force_remote_user = false
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
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          config.raw_arguments.each do |raw_arg|
            expect(args).to include(raw_arg)
          end
        }.and_return(default_execute_result)
      end

      it "sets raw arguments after arguments related to supported options" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args.index("--user=lion")).to be > args.index("--user=testuser")
          expect(args.index("--inventory-file=/forget/it/my/friend")).to be > args.index("--inventory-file=#{generated_inventory_dir}")
          expect(args.index("--limit=bar")).to be > args.index("--limit=all")
          expect(args.index("--skip-tags=ignored")).to be > args.index("--skip-tags=foo,bar")
        }.and_return(default_execute_result)
      end

      it "sets boolean flag (e.g. --sudo) defined in raw_arguments, even if corresponding option is set to false" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args).to include('--sudo')
        }.and_return(default_execute_result)
      end

    end

    describe "with limit option" do
      before do
        config.limit = %w(foo !bar)
      end

      it_should_set_arguments_and_environment_variables
    end

    context "with force_remote_user option disabled" do
      before do
        config.force_remote_user = false
      end

      it_should_create_and_use_generated_inventory false # i.e. without setting ansible_ssh_user in inventory

      it_should_set_arguments_and_environment_variables 6

      it "uses a --user argument to set a default remote user" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args).not_to include("--extra-vars=ansible_ssh_user='#{machine.ssh_info[:username]}'")
          expect(args).to include("--user=#{machine.ssh_info[:username]}")
        }.and_return(default_execute_result)
      end
    end

    context "with winrm communicator" do

      let(:iso_winrm_env) do
        env = isolated_environment
        env.vagrantfile <<-VF
Vagrant.configure("2") do |config|
  config.winrm.username = 'winner'
  config.winrm.password = 'winword'
  config.winrm.transport = :ssl

  config.vm.define :machine1 do |machine|
    machine.vm.box = "winbox"
    machine.vm.communicator = :winrm
  end
end
VF
        env.create_vagrant_env
      end

      let(:machine) { iso_winrm_env.machine(iso_winrm_env.machine_names[0], :dummy) }

      it_should_set_arguments_and_environment_variables

      it "generates an inventory with winrm connection settings" do

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(config.inventory_path).to be_nil
          expect(File.exists?(generated_inventory_file)).to be(true)
          inventory_content = File.read(generated_inventory_file)

          expect(inventory_content).to include("machine1 ansible_connection=winrm ansible_ssh_host=127.0.0.1 ansible_ssh_port=55986 ansible_ssh_user='winner' ansible_ssh_pass='winword'\n")
        }.and_return(default_execute_result)
      end

      describe "with force_remote_user option disabled" do
        before do
          config.force_remote_user = false
        end

        it "doesn't set the ansible remote user in inventory and use '--user' argument with the vagrant ssh username" do
          expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
            inventory_content = File.read(generated_inventory_file)

            expect(inventory_content).to include("machine1 ansible_connection=winrm ansible_ssh_host=127.0.0.1 ansible_ssh_port=55986 ansible_ssh_pass='winword'\n")
            expect(args).to include("--user=testuser")
          }.and_return(default_execute_result)
        end
      end
    end

    describe "with inventory_path option" do
      before do
        config.inventory_path = existing_file
      end

      it_should_set_arguments_and_environment_variables 6

      it "does not generate the inventory and uses given inventory path instead" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args).to include("--inventory-file=#{existing_file}")
          expect(args).not_to include("--inventory-file=#{generated_inventory_file}")
          expect(File.exists?(generated_inventory_file)).to be(false)
        }.and_return(default_execute_result)
      end

      it "uses an --extra-vars argument to force ansible_ssh_user parameter" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args).not_to include("--user=#{machine.ssh_info[:username]}")
          expect(args).to include("--extra-vars=ansible_ssh_user='#{machine.ssh_info[:username]}'")
        }.and_return(default_execute_result)
      end

      describe "with force_remote_user option disabled" do
        before do
          config.force_remote_user = false
        end

        it "uses a --user argument to set a default remote user" do
          expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
            expect(args).not_to include("--extra-vars=ansible_ssh_user='#{machine.ssh_info[:username]}'")
            expect(args).to include("--user=#{machine.ssh_info[:username]}")
          }.and_return(default_execute_result)
        end
      end
    end

    context "with config_file option defined" do
      before do
        config.config_file = existing_file
      end

      it "sets ANSIBLE_CONFIG environment variable" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]).to include("ANSIBLE_CONFIG")
          expect(cmd_opts[:env]['ANSIBLE_CONFIG']).to eql(existing_file)
        }.and_return(default_execute_result)
      end
    end

    describe "with ask_vault_pass option" do
      before do
        config.ask_vault_pass = true
      end

      it_should_set_arguments_and_environment_variables 6

      it "should ask the vault password" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args).to include("--ask-vault-pass")
        }.and_return(default_execute_result)
      end
    end

    describe "with vault_password_file option" do
      before do
        config.vault_password_file = existing_file
      end

      it_should_set_arguments_and_environment_variables 6

      it "uses the given vault password file" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args).to include("--vault-password-file=#{existing_file}")
        }.and_return(default_execute_result)
      end
    end

    describe "with raw_ssh_args" do
      before do
        config.raw_ssh_args = ['-o ControlMaster=no', '-o ForwardAgent=no']
      end

      it_should_set_arguments_and_environment_variables
      it_should_explicitly_enable_ansible_ssh_control_persist_defaults

      it "passes custom SSH options via ANSIBLE_SSH_ARGS with the highest priority" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          raw_opt_index = cmd_opts[:env]['ANSIBLE_SSH_ARGS'].index("-o ControlMaster=no")
          default_opt_index = cmd_opts[:env]['ANSIBLE_SSH_ARGS'].index("-o ControlMaster=auto")
          expect(raw_opt_index).to be < default_opt_index
        }.and_return(default_execute_result)
      end

      describe "and with ssh forwarding enabled" do
        before do
          ssh_info[:forward_agent] = true
        end

        it "sets '-o ForwardAgent=yes' via ANSIBLE_SSH_ARGS with higher priority than raw_ssh_args values" do
          expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
            cmd_opts = args.last
            forwardAgentYes = cmd_opts[:env]['ANSIBLE_SSH_ARGS'].index("-o ForwardAgent=yes")
            forwardAgentNo = cmd_opts[:env]['ANSIBLE_SSH_ARGS'].index("-o ForwardAgent=no")
            expect(forwardAgentYes).to be < forwardAgentNo
          }.and_return(default_execute_result)
        end
      end

    end

    describe "with multiple SSH identities" do
      before do
        ssh_info[:private_key_path] = ['/path/to/my/key', '/an/other/identity', '/yet/an/other/key']
      end

      it_should_set_arguments_and_environment_variables
      it_should_explicitly_enable_ansible_ssh_control_persist_defaults

      it "passes additional Identity Files via ANSIBLE_SSH_ARGS" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o IdentityFile=/an/other/identity")
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o IdentityFile=/yet/an/other/key")
        }.and_return(default_execute_result)
      end
    end

    describe "with an identity file containing `%`" do
      before do
        ssh_info[:private_key_path] = ['/foo%bar/key', '/bar%%buz/key']
      end

      it "replaces `%` with `%%`" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o IdentityFile=/foo%%bar/key")
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o IdentityFile=/bar%%%%buz/key")
        }.and_return(default_execute_result)
      end
    end

    describe "with ssh forwarding enabled" do
      before do
        ssh_info[:forward_agent] = true
      end

      it_should_set_arguments_and_environment_variables
      it_should_explicitly_enable_ansible_ssh_control_persist_defaults

      it "enables SSH-Forwarding via ANSIBLE_SSH_ARGS" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ForwardAgent=yes")
        }.and_return(default_execute_result)
      end
    end

    describe "with an ssh proxy command configured" do
      before do
        ssh_info[:proxy_command] = "ssh -W %h:%p -q user@remote_libvirt_host"
      end

      it "sets '-o ProxyCommand' via ANSIBLE_SSH_ARGS" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ProxyCommand='ssh -W %h:%p -q user@remote_libvirt_host'")
        }.and_return(default_execute_result)
      end
    end

    context "with verbose option defined" do
      %w(vv vvvv).each do |verbose_option|

        describe "with a value of '#{verbose_option}'" do
          before do
            config.verbose = verbose_option
          end

          it_should_set_arguments_and_environment_variables 6
          it_should_set_optional_arguments({ "verbose" => "-#{verbose_option}" })

          it "shows the ansible-playbook command and set verbosity to '-#{verbose_option}' level" do
            expect(machine.env.ui).to receive(:detail).with(any_args) { |full_command|
              expect(full_command).to eq("PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_HOST_KEY_CHECKING=false ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s' ansible-playbook --connection=ssh --timeout=30 --limit=\"machine1\" --inventory-file=#{generated_inventory_dir} -#{verbose_option} playbook.yml")
            }
          end
        end

        describe "with a value of '-#{verbose_option}'" do
          before do
            config.verbose = "-#{verbose_option}"
          end

          it_should_set_arguments_and_environment_variables 6
          it_should_set_optional_arguments({ "verbose" => "-#{verbose_option}" })

          it "shows the ansible-playbook command and set verbosity to '-#{verbose_option}' level" do
            expect(machine.env.ui).to receive(:detail).with(any_args) { |full_command|
              expect(full_command).to eq("PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_HOST_KEY_CHECKING=false ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s' ansible-playbook --connection=ssh --timeout=30 --limit=\"machine1\" --inventory-file=#{generated_inventory_dir} -#{verbose_option} playbook.yml")
            }
          end
        end
      end

      describe "with an invalid string" do
        before do
          config.verbose = "wrong"
        end

        it_should_set_arguments_and_environment_variables 6
        it_should_set_optional_arguments({ "verbose" => "-v" })

        it "shows the ansible-playbook command and set verbosity to '-v' level" do
          expect(machine.env.ui).to receive(:detail).with(any_args) { |full_command|
            expect(full_command).to eq("PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_HOST_KEY_CHECKING=false ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s' ansible-playbook --connection=ssh --timeout=30 --limit=\"machine1\" --inventory-file=#{generated_inventory_dir} -v playbook.yml")
          }
        end
      end

      describe "with an empty string" do
        before do
          config.verbose = ""
        end

        it_should_set_arguments_and_environment_variables

        it "doesn't show the ansible-playbook command" do
          expect(machine.env.ui).not_to receive(:detail).with(any_args) { |full_command|
            expect(full_command).to include("ansible-playbook")
          }
        end
      end

    end

    describe "without colorized output" do
      before do
        allow(machine.env).to receive(:ui).and_return(Vagrant::UI::Basic.new)
      end

      it "disables ansible-playbook colored output" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]).to_not include("ANSIBLE_FORCE_COLOR")
          expect(cmd_opts[:env]['ANSIBLE_NOCOLOR']).to eql("true")
        }.and_return(default_execute_result)
      end
    end

    describe "with galaxy support" do

      before do
        config.galaxy_role_file = existing_file
      end

      it "raises an error when ansible-galaxy command fails", skip_before: true, skip_after: true do
        config.finalize!

        allow(subject).to receive(:check_path)
        allow(Vagrant::Util::Subprocess).to receive(:execute)
          .and_return(Vagrant::Util::Subprocess::Result.new(1, "", ""))

        expect {subject.provision}.to raise_error(VagrantPlugins::Ansible::Errors::AnsibleCommandFailed)
      end

      it "execute ansible-galaxy, and then ansible-playbook" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |cmd, *args|
          expect(cmd).to eq("ansible-galaxy")
        }.and_return(default_execute_result)

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |cmd, *args|
          expect(cmd).to eq("ansible-playbook")
        }.and_return(default_execute_result)
      end

      describe "with verbose option enabled" do
        before do
          config.verbose = true
        end

        xit "shows the ansible-galaxy command in use"
      end
    end

    context "with galaxy_roles_path option defined" do
      before do
        config.galaxy_roles_path = "my-roles"
      end

      it "sets ANSIBLE_ROLES_PATH with corresponding absolute path" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]).to include("ANSIBLE_ROLES_PATH")
          expect(cmd_opts[:env]['ANSIBLE_ROLES_PATH']).to eql(File.join(machine.env.root_path, "my-roles"))
        }.and_return(default_execute_result)
      end
    end

    context "with extra_vars option defined" do
      describe "with a hash value" do
        before do
          config.extra_vars = { var1: %Q(string with 'apostrophes', \\, " and =), var2: { x: 42 } }
        end

        it_should_set_optional_arguments({ "extra_vars" => "--extra-vars={\"var1\":\"string with 'apostrophes', \\\\, \\\" and =\",\"var2\":{\"x\":42}}" })
      end

      describe "with a string value referring to file path (with the '@' prefix)" do
        before do
          config.extra_vars = "@#{existing_file}"
        end

        it_should_set_optional_arguments({ "extra_vars" => "--extra-vars=@#{File.expand_path(__FILE__)}" })
      end
    end

    # The Vagrant Ansible provisioner does not validate the coherency of
    # argument combinations, and let ansible-playbook complain.
    describe "with a maximum of options" do
      before do
        # vagrant general options
        ssh_info[:forward_agent] = true
        ssh_info[:private_key_path] = ['/my/key1', '/my/key2']

        # command line arguments
        config.galaxy_roles_path = "/up/to the stars"
        config.extra_vars = { var1: %Q(string with 'apostrophes', \\, " and =), var2: { x: 42 } }
        config.sudo = true
        config.sudo_user = 'deployer'
        config.verbose = "vvv"
        config.ask_sudo_pass = true
        config.ask_vault_pass = true
        config.vault_password_file = existing_file
        config.tags = %w(db www)
        config.skip_tags = %w(foo bar)
        config.limit = 'machine*:&vagrant:!that_one'
        config.start_at_task = "joe's awesome task"
        config.raw_arguments = ["--why-not", "--su-user=foot", "--ask-su-pass", "--limit=all", "--private-key=./myself.key", "--extra-vars='{\"var3\":\"foo\"}'"]

        # environment variables
        config.config_file = existing_file
        config.host_key_checking = true
        config.raw_ssh_args = ['-o ControlMaster=no']
      end

      it_should_set_arguments_and_environment_variables 21, 6, true
      it_should_explicitly_enable_ansible_ssh_control_persist_defaults
      it_should_set_optional_arguments({  "extra_vars"          => "--extra-vars={\"var1\":\"string with 'apostrophes', \\\\, \\\" and =\",\"var2\":{\"x\":42}}",
                                          "sudo"                => "--sudo",
                                          "sudo_user"           => "--sudo-user=deployer",
                                          "verbose"             => "-vvv",
                                          "ask_sudo_pass"       => "--ask-sudo-pass",
                                          "ask_vault_pass"      => "--ask-vault-pass",
                                          "vault_password_file" => "--vault-password-file=#{File.expand_path(__FILE__)}",
                                          "tags"                => "--tags=db,www",
                                          "skip_tags"           => "--skip-tags=foo,bar",
                                          "limit"               => "--limit=machine*:&vagrant:!that_one",
                                          "start_at_task"       => "--start-at-task=joe's awesome task",
                                        })

      it "also includes given raw arguments" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args).to include("--why-not")
          expect(args).to include("--su-user=foot")
          expect(args).to include("--ask-su-pass")
          expect(args).to include("--limit=all")
          expect(args).to include("--private-key=./myself.key")
        }.and_return(default_execute_result)
      end

      it "shows the ansible-playbook command, with additional quotes when required" do
        expect(machine.env.ui).to receive(:detail).with(any_args) { |full_command|
          expect(full_command).to eq(%Q(PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ANSIBLE_ROLES_PATH='/up/to the stars' ANSIBLE_CONFIG='#{existing_file}' ANSIBLE_HOST_KEY_CHECKING=true ANSIBLE_SSH_ARGS='-o IdentitiesOnly=yes -o IdentityFile=/my/key1 -o IdentityFile=/my/key2 -o ForwardAgent=yes -o ControlMaster=no -o ControlMaster=auto -o ControlPersist=60s' ansible-playbook --connection=ssh --timeout=30 --ask-sudo-pass --ask-vault-pass --limit="machine*:&vagrant:!that_one" --inventory-file=#{generated_inventory_dir} --extra-vars="{\\"var1\\":\\"string with 'apostrophes', \\\\\\\\, \\\\\\" and =\\",\\"var2\\":{\\"x\\":42}}" --sudo --sudo-user=deployer -vvv --vault-password-file=#{existing_file} --tags=db,www --skip-tags=foo,bar --start-at-task="joe's awesome task" --why-not --su-user=foot --ask-su-pass --limit=all --private-key=./myself.key --extra-vars='{\"var3\":\"foo\"}' playbook.yml))
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
          allow(h).to receive(:ssh_info).and_return(fake_host_ssh_info)
        end
      }

      before do
        allow(machine).to receive(:provider_name).and_return(:docker)
        allow(machine.provider).to receive(:host_vm?).and_return(true)
        allow(machine.provider).to receive(:host_vm).and_return(fake_host_vm)
      end

      it "uses an SSH ProxyCommand to reach the VM" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to include("-o ProxyCommand='ssh boot9docker@127.0.0.1 -p 2299 -i /path/to/docker/host/key -o Compression=yes -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no exec nc %h %p 2>/dev/null'")
        }.and_return(default_execute_result)
      end
    end

    #
    # Special cases related to the Vagrant Host operating system in use
    #

    context "on a Windows host" do
      before do
        allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
        allow(machine.ui).to receive(:warn)
      end

      it "warns that Windows is not officially supported for the Ansible control machine" do
        expect(machine.env.ui).to receive(:warn).with(any_args) { |warning|
          expect(warning).to eq(I18n.t("vagrant.provisioners.ansible.windows_not_supported_for_control_machine"))
        }
      end
    end

    context "on a Solaris-like host" do
      before do
        allow(Vagrant::Util::Platform).to receive(:solaris?).and_return(true)
      end

      it "does not set IdentitiesOnly=yes in ANSIBLE_SSH_ARGS" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to_not include("-o IdentitiesOnly=yes")
        }.and_return(default_execute_result)
      end

      describe "and with host_key_checking option enabled" do
        it "does not set ANSIBLE_SSH_ARGS environment variable" do
          config.host_key_checking = true

          expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
            cmd_opts = args.last
            expect(cmd_opts[:env]).to_not include('ANSIBLE_SSH_ARGS')
          }.and_return(Vagrant::Util::Subprocess::Result.new(0, "", ""))
        end
      end

    end

    describe 'with config.ssh.keys_only = false' do
      it 'does not set IdentitiesOnly=yes in ANSIBLE_SSH_ARGS' do
        ssh_info[:keys_only] = false

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          cmd_opts = args.last
          expect(cmd_opts[:env]['ANSIBLE_SSH_ARGS']).to_not include("-o IdentitiesOnly=yes")
        }.and_return(default_execute_result)
      end
    end
  end
end
