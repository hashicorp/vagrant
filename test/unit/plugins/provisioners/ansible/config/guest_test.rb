require_relative "../../../../base"
require_relative "../../support/shared/config"
require_relative "shared"

require Vagrant.source_root.join("plugins/provisioners/ansible/config/guest")

describe VagrantPlugins::Ansible::Config::Guest do
  include_context "unit"

  subject { described_class.new }

  # FIXME: machine.ui.warn stub is not working as expected...
  let(:machine) { double("machine", env: Vagrant::Environment.new) }

  let(:communicator) { double("communicator") }
  let(:existing_file) { "this/path/is/a/stub" }
  let(:non_existing_file) { "this/path/does/not/exist" }

  it "supports a list of options" do
    supported_options = %w( extra_vars
                            galaxy_command
                            galaxy_role_file
                            galaxy_roles_path
                            groups
                            host_vars
                            install
                            inventory_path
                            limit
                            playbook
                            provisioning_path
                            raw_arguments
                            skip_tags
                            start_at_task
                            sudo
                            sudo_user
                            tags
                            tmp_path
                            vault_password_file
                            verbose
                            version )

    expect(get_provisioner_option_names(described_class)).to eql(supported_options)
  end

  describe "default options handling" do
    it_behaves_like "options shared by both Ansible provisioners"

    it "assigns default values to unset guest-specific options" do
      subject.finalize!

      expect(subject.install).to be_true
      expect(subject.provisioning_path).to eql("/vagrant")
      expect(subject.tmp_path).to eql("/tmp/vagrant-ansible")
      expect(subject.version).to be_empty
    end
  end

  describe "#validate" do
    before do
      machine.stub(communicate: communicator)
    end

    context "when the machine is not ready to communicate" do
      before do
        allow(communicator).to receive(:ready?).and_return(false)
      end

      it "cannot check the existence of remote file" do
        subject.playbook = non_existing_file
        subject.finalize!

        result = subject.validate(machine)
        expect(result["ansible local provisioner"]).to eql([])
        # FIXME: commented out because this `communicator.ready?` stub is not working as expected
        # expect(communicator).to receive(:ready?).ordered
        # Note that communicator mock will fail if it receives an unexpected message,
        # which is part of this spec.
      end
    end

    context "when the machine is ready to communicate" do
      before do
        allow(communicator).to receive(:ready?).and_return(true)
        allow(communicator).to receive(:test).and_return(false)

        allow(communicator).to receive(:test) do |arg1|
          arg1.include?("#{existing_file}")
        end

        stubbed_ui = Vagrant::UI::Colored.new
        machine.stub(ui: stubbed_ui)
        allow(machine.ui).to receive(:warn)

        subject.playbook = existing_file
      end

      it_behaves_like "an Ansible provisioner", "/vagrant", "local"

      it "only shows a warning if the playbook file does not exist" do
        subject.playbook = non_existing_file
        subject.finalize!

        result = subject.validate(machine)
        expect(result["ansible remote provisioner"]).to be_nil

        # FIXME
        # expect(machine).to receive(:ui).with { |warning_text|
        #     expect(warning_text).to eq("`playbook` does not exist on the guest: /vagrant/this/path/does/not/exist")
        #   }
      end

      it "only shows a warning if inventory_path is specified, but does not exist" do
        subject.inventory_path = non_existing_file
        subject.finalize!

        result = subject.validate(machine)
        expect(result["ansible remote provisioner"]).to be_nil

        # FIXME
        # expect(machine.ui).to receive(:warn).with { |warning_text|
        #      expect(warning_text).to eq("`inventory_path` does not exist on the guest: this/path/does/not/exist")
        #    }
      end

      it "only shows a warning if vault_password_file is specified, but does not exist" do
        subject.vault_password_file = non_existing_file
        subject.finalize!

        result = subject.validate(machine)
        expect(result["ansible remote provisioner"]).to be_nil

        # FIXME
        # expect(machine.ui).to receive(:warn).with { |warning_text|
        #      expect(warning_text).to eq("`inventory_path` does not exist on the guest: this/path/does/not/exist")
        #    }
      end

      it "it doesn't consider missing files on the remote system as errors" do
        subject.playbook = non_existing_file
        subject.inventory_path = non_existing_file
        subject.extra_vars = non_existing_file
        subject.finalize!

        result = subject.validate(machine)
        expect(result["ansible local provisioner"]).to include(
          I18n.t("vagrant.provisioners.ansible.errors.extra_vars_invalid",
                 type:  subject.extra_vars.class.to_s,
                 value: subject.extra_vars.to_s))

        expect(result["ansible local provisioner"]).to_not include(
          I18n.t("vagrant.provisioners.ansible.errors.playbook_path_invalid",
                 path: File.join("/vagrant", non_existing_file), system: "guest"))

        expect(result["ansible local provisioner"]).to_not include(
          I18n.t("vagrant.provisioners.ansible.errors.inventory_path_invalid",
                 path: File.join("/vagrant", non_existing_file), system: "guest"))
      end

    end

  end

end
