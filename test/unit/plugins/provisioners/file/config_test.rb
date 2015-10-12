require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/file/config")

describe VagrantPlugins::FileUpload::Config do
  include_context "unit"

  subject { described_class.new }

  let(:env) do
    iso_env = isolated_environment
    iso_env.vagrantfile("")
    iso_env.create_vagrant_env
  end

  let(:machine) { double("machine", env: env) }

  describe "#validate" do
    it "returns an error if destination is not specified" do
      existing_file = File.expand_path(__FILE__)

      subject.source = existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["File provisioner"]).to eql([
        I18n.t("vagrant.provisioners.file.no_dest_file")
      ])
    end

    it "returns an error if source is not specified" do
      subject.destination = "/tmp/foo"
      subject.finalize!

      result = subject.validate(machine)
      expect(result["File provisioner"]).to eql([
        I18n.t("vagrant.provisioners.file.no_source_file")
      ])
    end

    it "returns an error if source file does not exist" do
      non_existing_file = "/this/does/not/exist"

      subject.source = non_existing_file
      subject.destination = "/tmp/foo"
      subject.finalize!

      result = subject.validate(machine)
      expect(result["File provisioner"]).to eql([
        I18n.t("vagrant.provisioners.file.path_invalid",
               path: File.expand_path(non_existing_file))
      ])
    end

    it "passes with absolute source path" do
      existing_absolute_path = File.expand_path(__FILE__)

      subject.source = existing_absolute_path
      subject.destination = "/tmp/foo"
      subject.finalize!

      result = subject.validate(machine)
      expect(result["File provisioner"]).to eql([])
    end

    it "passes with relative source path" do
      path = env.root_path.join("foo")
      path.open("w+") { |f| f.write("hello") }

      existing_relative_path = "foo"

      subject.source = existing_relative_path
      subject.destination = "/tmp/foo"
      subject.finalize!

      result = subject.validate(machine)
      expect(result["File provisioner"]).to eql([])
    end
  end
end
