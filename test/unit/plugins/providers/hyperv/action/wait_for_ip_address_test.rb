require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/wait_for_ip_address")

describe VagrantPlugins::HyperV::Action::WaitForIPAddress do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, provider_config: provider_config) }
  let(:provider_config){ double("provider_config", ip_address_timeout: ip_address_timeout, ipv4_only: ipv4_only) }
  let(:ip_address_timeout){ 1 }
  let(:ipv4_only){ false }

  let(:subject){ described_class.new(app, env) }

  before do
    allow(driver).to receive(:read_guest_ip).and_return("ip" => "127.0.0.1")
    allow(app).to receive(:call)
    allow(Vagrant::Util::Platform).to receive(:wsl?).and_return(false)
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  it "should set a timeout for waiting" do
    expect(Timeout).to receive(:timeout).with(ip_address_timeout)
    subject.call(env)
  end

  it "should retry until it receives a valid address" do
    expect(driver).to receive(:read_guest_ip).and_return("ip" => "ADDRESS")
    expect(driver).to receive(:read_guest_ip).and_return("ip" => "127.0.0.1")
    expect(subject).to receive(:sleep)
    subject.call(env)
  end

  it "should call the app on success with IPv6 address" do
    expect(driver).to receive(:read_guest_ip).and_return("ip" => "FE80:0000:0000:0000:0202:B3FF:FE1E:8329")
    subject.call(env)
  end

  context "IPv4_only" do
    let(:ipv4_only){ true }

    it "should call the app on success" do
      expect(app).to receive(:call)
      subject.call(env)
    end

    it "should set a timeout for waiting for IPv4 address" do
      expect(Timeout).to receive(:timeout).with(ip_address_timeout)
      subject.call(env)
    end

    it "should retry until it receives a valid IPv4 address" do
      expect(driver).to receive(:read_guest_ip).and_return("ip" => "FE80:0000:0000:0000:0202:B3FF:FE1E:8329")
      expect(driver).to receive(:read_guest_ip).and_return("ip" => "127.0.0.1")
      expect(subject).to receive(:sleep)
      subject.call(env)
    end
  end
end
