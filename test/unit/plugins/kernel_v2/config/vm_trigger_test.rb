require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vm_trigger")

describe VagrantPlugins::Kernel_V2::VagrantConfigTrigger do
  include_context "unit"

  let(:command) { :up }

  subject { described_class.new(command) }

  let(:machine) { double("machine") }

  def assert_invalid
    errors = subject.validate(machine)
    if errors.empty?
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.empty?
      raise "Errors: #{errors.inspect}"
    end
  end

  before do
    env = double("env")
    allow(env).to receive(:root_path).and_return(nil)
    allow(machine).to receive(:env).and_return(env)
    allow(machine).to receive(:provider_config).and_return(nil)
    allow(machine).to receive(:provider_options).and_return({})

    subject.name = "foo"
    subject.info = "Hello there"
    subject.warn = "Warning!!"
    subject.ignore = :up
    subject.only_on = "guest"
    subject.ruby do |env,machine|
      var = 'test'
      math = 1+1
    end
    subject.run = {inline: "apt-get update"}
    subject.run_remote = {inline: "apt-get update", env: {"VAR"=>"VAL"}}
  end

  describe "with defaults" do
    it "is valid with test defaults" do
      subject.finalize!
      assert_valid
    end

    it "sets a command" do
      subject.finalize!
      expect(subject.command).to eq(command)
    end

    it "uses default error behavior" do
      subject.finalize!
      expect(subject.on_error).to eq(:halt)
    end
  end

  describe "defining a new config that needs to match internal restraints" do
    let(:cmd) { :destroy }
    let(:cfg) { described_class.new(cmd) }
    let(:arr_cfg) { described_class.new(cmd) }

    before do
      cfg.only_on = :guest
      cfg.ignore = "up"
      cfg.abort = true
      cfg.type = "action"
      cfg.ruby do
        var = 1+1
      end
      arr_cfg.only_on = ["guest", /other/]
      arr_cfg.ignore = ["up", "destroy"]
    end

    it "ensures only_on is an array" do
      cfg.finalize!
      arr_cfg.finalize!

      expect(cfg.only_on).to be_a(Array)
      expect(arr_cfg.only_on).to be_a(Array)
    end

    it "ensures ignore is an array of symbols" do
      cfg.finalize!
      arr_cfg.finalize!

      expect(cfg.ignore).to be_a(Array)
      expect(arr_cfg.ignore).to be_a(Array)

      cfg.ignore.each do |a|
        expect(a).to be_a(Symbol)
      end

      arr_cfg.ignore.each do |a|
        expect(a).to be_a(Symbol)
      end
    end

    it "ensures ruby is a proc" do
      cfg.finalize!
      expect(cfg.ruby_block).to be_a(Proc)
    end

    it "converts aborts true to exit code 0" do
      cfg.finalize!

      expect(cfg.abort).to eq(1)
    end

    it "converts types to symbols" do
      cfg.finalize!
      expect(cfg.type).to eq(:action)
    end
  end

  describe "defining a basic trigger config" do
    let(:cmd) { :up }
    let(:cfg) { described_class.new(cmd) }

    before do
      cfg.info = "Hello there"
      cfg.warn = "Warning!!"
      cfg.on_error = :continue
      cfg.ignore = :up
      cfg.abort = 3
      cfg.only_on = "guest"
      cfg.ruby = proc{ var = 1+1 }
      cfg.run = {inline: "apt-get update"}
      cfg.run_remote = {inline: "apt-get update", env: {"VAR"=>"VAL"}}
    end

    it "sets the options" do
      cfg.finalize!
      expect(cfg.info).to eq("Hello there")
      expect(cfg.warn).to eq("Warning!!")
      expect(cfg.on_error).to eq(:continue)
      expect(cfg.ignore).to eq([:up])
      expect(cfg.only_on).to eq(["guest"])
      expect(cfg.run).to be_a(VagrantPlugins::Shell::Config)
      expect(cfg.run_remote).to be_a(VagrantPlugins::Shell::Config)
      expect(cfg.abort).to eq(3)
      expect(cfg.ruby_block).to be_a(Proc)
    end
  end
end
