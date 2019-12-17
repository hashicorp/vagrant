require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Disk do
  let(:app) { lambda { |env| } }
  let(:vm) { double("vm") }
  let(:config) { double("config", vm: vm) }
  let(:provider) { double("provider") }
  let(:machine) { double("machine", config: config, provider: provider, provider_name: "provider") }
  let(:env) { { ui: ui, machine: machine} }

  let(:disks) { [double("disk")] }

  let(:ui)  { double("ui") }

  describe "#call" do
    it "calls configure_disks if disk config present" do
      allow(vm).to receive(:disks).and_return(disks)
      allow(machine).to receive(:disks).and_return(disks)
      allow(machine.provider).to receive(:capability?).with(:configure_disks).and_return(true)
      subject = described_class.new(app, env)

      expect(app).to receive(:call).with(env).ordered
      expect(machine.provider).to receive(:capability).with(:configure_disks, disks)

      subject.call(env)
    end

    it "continues on if no disk config present" do
      allow(vm).to receive(:disks).and_return([])
      subject = described_class.new(app, env)

      expect(app).to receive(:call).with(env).ordered
      expect(machine.provider).not_to receive(:capability).with(:configure_disks, disks)

      subject.call(env)
    end

    it "prints a warning if disk config capability is unsupported" do
      allow(vm).to receive(:disks).and_return(disks)
      allow(machine.provider).to receive(:capability?).with(:configure_disks).and_return(false)
      subject = described_class.new(app, env)

      expect(app).to receive(:call).with(env).ordered
      expect(machine.provider).not_to receive(:capability).with(:configure_disks, disks)
      expect(ui).to receive(:warn)

      subject.call(env)
    end
  end
end
