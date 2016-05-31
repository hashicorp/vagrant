shared_examples_for 'options shared by both Ansible provisioners' do

  it "assigns default values to unset common options" do
    subject.finalize!

    expect(subject.extra_vars).to be_nil
    expect(subject.galaxy_command).to eql("ansible-galaxy install --role-file=%{role_file} --roles-path=%{roles_path} --force")
    expect(subject.galaxy_role_file).to be_nil
    expect(subject.galaxy_roles_path).to be_nil
    expect(subject.groups).to eq({})
    expect(subject.host_vars).to eq({})
    expect(subject.inventory_path).to be_nil
    expect(subject.limit).to be_nil
    expect(subject.playbook).to be_nil
    expect(subject.raw_arguments).to be_nil
    expect(subject.skip_tags).to be_nil
    expect(subject.start_at_task).to be_nil
    expect(subject.sudo).to be_false
    expect(subject.sudo_user).to be_nil
    expect(subject.tags).to be_nil
    expect(subject.vault_password_file).to be_nil
    expect(subject.verbose).to be_false
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
    subject.playbook = nil
    subject.extra_vars = ["var1", 3, "var2", 5]
    subject.raw_arguments = { arg1: 1, arg2: "foo" }
    subject.finalize!

    result = subject.validate(machine)

    expect(result[provisioner_label].size).to eql(3)
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

  describe "sudo option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :sudo, false
  end

end
