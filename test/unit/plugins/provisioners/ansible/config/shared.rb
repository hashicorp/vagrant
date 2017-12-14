shared_examples_for 'options shared by both Ansible provisioners' do

  it "assigns default values to unset common options" do
    subject.finalize!

    expect(subject.become).to be(false)
    expect(subject.become_user).to be_nil
    expect(subject.compatibility_mode).to eql(VagrantPlugins::Ansible::COMPATIBILITY_MODE_AUTO)
    expect(subject.config_file).to be_nil
    expect(subject.extra_vars).to be_nil
    expect(subject.galaxy_command).to eql("ansible-galaxy install --role-file=%{role_file} --roles-path=%{roles_path} --force")
    expect(subject.galaxy_role_file).to be_nil
    expect(subject.galaxy_roles_path).to be_nil
    expect(subject.groups).to eq({})
    expect(subject.host_vars).to eq({})
    expect(subject.inventory_path).to be_nil
    expect(subject.limit).to be_nil
    expect(subject.playbook).to be_nil
    expect(subject.playbook_command).to eql("ansible-playbook")
    expect(subject.raw_arguments).to be_nil
    expect(subject.skip_tags).to be_nil
    expect(subject.start_at_task).to be_nil
    expect(subject.sudo).to be(false)              # deprecated
    expect(subject.sudo_user).to be_nil            # deprecated
    expect(subject.tags).to be_nil
    expect(subject.vault_password_file).to be_nil
    expect(subject.verbose).to be(false)
    expect(subject.version).to be_empty
  end

end

shared_examples_for 'any deprecated option' do |deprecated_option, new_option, option_value|
  it "shows the deprecation message" do
    expect($stdout).to receive(:puts).with("DEPRECATION: The '#{deprecated_option}' option for the Ansible provisioner is deprecated.").and_return(nil)
    expect($stdout).to receive(:puts).with("Please use the '#{new_option}' option instead.").and_return(nil)
    expect($stdout).to receive(:puts).with("The '#{deprecated_option}' option will be removed in a future release of Vagrant.\n\n").and_return(nil)

    subject.send("#{deprecated_option}=", option_value)
    subject.finalize!
  end
end

shared_examples_for 'an Ansible provisioner' do | path_prefix, ansible_setup |

  provisioner_label  = "ansible #{ansible_setup} provisioner"
  provisioner_system = ansible_setup == "local" ? "guest" : "host"

  it "returns an error if the playbook option is undefined" do
    subject.playbook = nil
    subject.finalize!

    result = subject.validate(machine)
    expect(result[provisioner_label]).to eql([
      I18n.t("vagrant.provisioners.ansible.errors.no_playbook")
    ])
  end

  describe "compatibility_mode option" do

    VagrantPlugins::Ansible::COMPATIBILITY_MODES.each do |valid_mode|
      it "supports compatibility mode '#{valid_mode}'" do
        subject.compatibility_mode = valid_mode
        subject.finalize!

        result = subject.validate(machine)
        expect(subject.compatibility_mode).to eql(valid_mode)
      end
    end

    it "returns an error if the compatibility mode is not set" do
      subject.compatibility_mode = nil
      subject.finalize!

      result = subject.validate(machine)
      expect(result[provisioner_label]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.no_compatibility_mode",
               valid_modes: "'auto', '1.8', '2.0'")
      ])
    end

    %w(invalid 1.9 2.3).each do |invalid_mode|
      it "returns an error if the compatibility mode is invalid (e.g. '#{invalid_mode}')" do
        subject.compatibility_mode = invalid_mode
        subject.finalize!

        result = subject.validate(machine)
        expect(result[provisioner_label]).to eql([
          I18n.t("vagrant.provisioners.ansible.errors.no_compatibility_mode",
                 valid_modes: "'auto', '1.8', '2.0'")
        ])
      end
    end

  end

  it "passes if the extra_vars option is a hash" do
    subject.extra_vars = { var1: 1, var2: "foo" }
    subject.finalize!

    result = subject.validate(machine)
    expect(result[provisioner_label]).to eql([])
  end

  it "returns an error if the extra_vars option is of wrong data type" do
    subject.extra_vars = ["var1", 3, "var2", 5]
    subject.finalize!

    result = subject.validate(machine)
    expect(result[provisioner_label]).to eql([
      I18n.t("vagrant.provisioners.ansible.errors.extra_vars_invalid",
             type:  subject.extra_vars.class.to_s,
             value: subject.extra_vars.to_s)
    ])
  end

  it "converts a raw_arguments option defined as a String into an Array" do
    subject.raw_arguments = "--foo=bar"
    subject.finalize!

    result = subject.validate(machine)
    expect(subject.raw_arguments).to eql(%w(--foo=bar))
  end

  it "returns an error if the raw_arguments is of the wrong data type" do
    subject.raw_arguments = { arg1: 1, arg2: "foo" }
    subject.finalize!

    result = subject.validate(machine)
    expect(result[provisioner_label]).to eql([
      I18n.t("vagrant.provisioners.ansible.errors.raw_arguments_invalid",
             type:  subject.raw_arguments.class.to_s,
             value: subject.raw_arguments.to_s)
    ])
  end

  it "it collects and returns all detected errors" do
    subject.compatibility_mode = nil
    subject.playbook = nil
    subject.extra_vars = ["var1", 3, "var2", 5]
    subject.raw_arguments = { arg1: 1, arg2: "foo" }
    subject.finalize!

    result = subject.validate(machine)

    expect(result[provisioner_label].size).to eql(4)
    expect(result[provisioner_label]).to include(
      I18n.t("vagrant.provisioners.ansible.errors.no_compatibility_mode",
             valid_modes: "'auto', '1.8', '2.0'"))
    expect(result[provisioner_label]).to include(
      I18n.t("vagrant.provisioners.ansible.errors.no_playbook"))
    expect(result[provisioner_label]).to include(
      I18n.t("vagrant.provisioners.ansible.errors.extra_vars_invalid",
             type:  subject.extra_vars.class.to_s,
             value: subject.extra_vars.to_s))
    expect(result[provisioner_label]).to include(
      I18n.t("vagrant.provisioners.ansible.errors.raw_arguments_invalid",
             type:  subject.raw_arguments.class.to_s,
             value: subject.raw_arguments.to_s))
  end

  describe "become option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :become, false
  end

  describe "sudo option" do
    before do
      # Filter the deprecation notice
      allow($stdout).to receive(:puts)
    end
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :sudo, false
    it_behaves_like "any deprecated option", :sudo, :become, true
  end

  describe "sudo_user option" do
    before do
      # Filter the deprecation notice
      allow($stdout).to receive(:puts)
    end
    it_behaves_like "any deprecated option", :sudo_user, :become_user, "foo"
  end

end
