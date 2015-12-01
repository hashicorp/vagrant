require_relative "../../../base"
require_relative "../support/shared/config"

require "vagrant/util/platform"

require Vagrant.source_root.join("plugins/provisioners/ansible/config/host")

describe VagrantPlugins::Ansible::Config::Host do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine", env: Vagrant::Environment.new) }
  let(:existing_file) { File.expand_path(__FILE__) }
  let(:non_existing_file) do
    next "/this/does/not/exist" if !Vagrant::Util::Platform.windows?
    "C:/foo/nope/nope"
  end

  it "supports a list of options" do
    config_options = subject.public_methods(false).find_all { |i| i.to_s.end_with?('=') }
    config_options.map! { |i| i.to_s.sub('=', '') }

    supported_options = %w( ask_sudo_pass
                            ask_vault_pass
                            extra_vars
                            force_remote_user
                            galaxy_command
                            galaxy_role_file
                            galaxy_roles_path
                            groups
                            host_key_checking
                            host_vars
                            inventory_path
                            limit
                            playbook
                            raw_arguments
                            raw_ssh_args
                            skip_tags
                            start_at_task
                            sudo
                            sudo_user
                            tags
                            vault_password_file
                            verbose )

    expect(get_provisioner_option_names(described_class)).to eql(supported_options)
  end

  it "assigns default values to unset options" do
    subject.finalize!

    expect(subject.playbook).to be_nil
    expect(subject.extra_vars).to be_nil
    expect(subject.force_remote_user).to be_true
    expect(subject.ask_sudo_pass).to be_false
    expect(subject.ask_vault_pass).to be_false
    expect(subject.vault_password_file).to be_nil
    expect(subject.limit).to be_nil
    expect(subject.sudo).to be_false
    expect(subject.sudo_user).to be_nil
    expect(subject.verbose).to be_false
    expect(subject.tags).to be_nil
    expect(subject.skip_tags).to be_nil
    expect(subject.start_at_task).to be_nil
    expect(subject.host_vars).to eq({})
    expect(subject.groups).to eq({})
    expect(subject.host_key_checking).to be_false
    expect(subject.raw_arguments).to be_nil
    expect(subject.raw_ssh_args).to be_nil
  end

  describe "force_remote_user option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :force_remote_user, true
  end
  describe "host_key_checking option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :host_key_checking, false
  end
  describe "ask_sudo_pass option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :ask_sudo_pass, false
  end
  describe "ask_vault_pass option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :ask_sudo_pass, false
  end
  describe "sudo option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :sudo, false
  end

  describe "#validate" do
    before do
      subject.playbook = existing_file
    end

    it "passes if the playbook option refers to an existing file" do
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([])
    end

    it "returns an error if the playbook option is undefined" do
      subject.playbook = nil
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.no_playbook")
      ])
    end

    it "returns an error if the playbook file does not exist" do
      subject.playbook = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.playbook_path_invalid",
               path: non_existing_file, system: "host")
      ])
    end

    it "passes if the extra_vars option refers to an existing file" do
      subject.extra_vars = existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([])
    end

    it "passes if the extra_vars option is a hash" do
      subject.extra_vars = { var1: 1, var2: "foo" }
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([])
    end

    it "returns an error if the extra_vars option refers to a file that does not exist" do
      subject.extra_vars = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.extra_vars_invalid",
               type:  subject.extra_vars.class.to_s,
               value: subject.extra_vars.to_s)
      ])
    end

    it "returns an error if the extra_vars option is of wrong data type" do
      subject.extra_vars = ["var1", 3, "var2", 5]
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.extra_vars_invalid",
               type:  subject.extra_vars.class.to_s,
               value: subject.extra_vars.to_s)
      ])
    end

    it "passes if inventory_path refers to an existing location" do
      subject.inventory_path = existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([])
    end

    it "returns an error if inventory_path is specified, but does not exist" do
      subject.inventory_path = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.inventory_path_invalid",
               path: non_existing_file, system: "host")
      ])
    end

    it "returns an error if vault_password_file is specified, but does not exist" do
      subject.vault_password_file = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.vault_password_file_invalid",
               path: non_existing_file, system: "host")
      ])
    end

    it "returns an error if galaxy_role_file is specified, but does not exist" do
      subject.galaxy_role_file = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.galaxy_role_file_invalid",
               path: non_existing_file, system: "host")
      ])
    end

    it "it collects and returns all detected errors" do
      subject.playbook = non_existing_file
      subject.inventory_path = non_existing_file
      subject.extra_vars = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to include(
        I18n.t("vagrant.provisioners.ansible.errors.playbook_path_invalid",
               path: non_existing_file, system: "host"))
      expect(result["ansible remote provisioner"]).to include(
        I18n.t("vagrant.provisioners.ansible.errors.extra_vars_invalid",
               type:  subject.extra_vars.class.to_s,
               value: subject.extra_vars.to_s))
      expect(result["ansible remote provisioner"]).to include(
        I18n.t("vagrant.provisioners.ansible.errors.inventory_path_invalid",
               path: non_existing_file, system: "host"))
    end

  end

end
