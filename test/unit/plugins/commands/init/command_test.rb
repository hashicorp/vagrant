require_relative "../../../base"
require_relative "../../../../../plugins/commands/init/command"

describe VagrantPlugins::CommandInit::Command do
  include_context "unit"
  include_context "command plugin helpers"

  let(:iso_env) do
    isolated_environment
  end

  let(:env) do
    iso_env.create_vagrant_env
  end

  let(:vagrantfile_path) { File.join(env.cwd, "Vagrantfile") }

  before do
    allow(Vagrant.plugin("2").manager).to receive(:commands).and_return({})
  end

  after do
    iso_env.close
  end

  describe "#execute" do
    it "creates a Vagrantfile with no args" do
      described_class.new([], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.box = "base"/)
    end

    it "creates a minimal Vagrantfile" do
      described_class.new(["-m"], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to_not match(/#/)
      expect(contents).to_not match(/provision/)
    end

    it "creates a custom Vagrantfile using a relative template path" do
      described_class.new(["--template", "test/unit/templates/commands/init/Vagrantfile"], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.hostname = "vagrant.dev"/)
    end

    it "creates a custom Vagrantfile using an absolute template path" do
      described_class.new(["--template", ::Vagrant.source_root.join("test/unit/templates/commands/init/Vagrantfile").to_s], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.hostname = "vagrant.dev"/)
    end

    it "creates a custom Vagrantfile using a provided template with the extension included" do
      described_class.new(["--template", ::Vagrant.source_root.join("test/unit/templates/commands/init/Vagrantfile.erb").to_s], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.hostname = "vagrant.dev"/)
    end

    it "ignores the -m option when using a provided template" do
      described_class.new(["-m", "--template", ::Vagrant.source_root.join("test/unit/templates/commands/init/Vagrantfile").to_s], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.hostname = "vagrant.dev"/)
    end

    it "raises an appropriate exception when the template file can't be found" do
      expect {
      described_class.new(["--template", "./a/b/c/template"], env).execute
      }.to raise_error(Vagrant::Errors::VagrantfileTemplateNotFoundError)
    end

    it "does not overwrite an existing Vagrantfile" do
      # Create an existing Vagrantfile
      File.open(File.join(env.cwd, "Vagrantfile"), "w+") { |f| f.write("") }

      expect {
        described_class.new([], env).execute
      }.to raise_error(Vagrant::Errors::VagrantfileExistsError)
    end

    it "overwrites an existing Vagrantfile with force" do
      # Create an existing Vagrantfile
      File.open(File.join(env.cwd, "Vagrantfile"), "w+") { |f| f.write("") }

      expect {
        described_class.new(["-f"], env).execute
      }.to_not raise_error

      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.box = "base"/)
    end

    it "creates a Vagrantfile with a box" do
      described_class.new(["hashicorp/precise64"], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.box = "hashicorp\/precise64"/)
    end

    it "creates a Vagrantfile with a box and box_url" do
      described_class.new(["hashicorp/precise64", "http://mybox.com"], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.box = "hashicorp\/precise64"/)
      expect(contents).to match(/config.vm.box_url = "http:\/\/mybox.com"/)
    end

    it "creates a Vagrantfile with a box and box version" do
      described_class.new(["--box-version", "1.2.3", "hashicorp/precise64"], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.box = "hashicorp\/precise64"/)
      expect(contents).to match(/config.vm.box_version = "1.2.3"/)
    end

    it "creates a minimal Vagrantfile with a box and box version" do
      described_class.new(["--minimal", "--box-version", "1.2.3", "hashicorp/precise64"], env).execute
      contents = File.read(vagrantfile_path)
      expect(contents).to match(/config.vm.box = "hashicorp\/precise64"/)
      expect(contents).to match(/config.vm.box_version = "1.2.3"/)
    end

    it "creates a Vagrantfile at a custom path" do
      described_class.new(["--output", "vf.rb"], env).execute
      expect(File.exist?(File.join(env.cwd, "vf.rb"))).to be(true)
    end
  end
end
