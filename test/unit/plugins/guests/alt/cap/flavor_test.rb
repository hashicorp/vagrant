require_relative "../../../../base"

describe "VagrantPlugins::GuestALT::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestALT::Plugin
      .components
      .guest_capabilities[:alt]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".flavor" do
    let(:cap) { caps.get(:flavor) }

    context "without /etc/os-release file" do
      {
        "ALT 8.1 Server" => :alt_8,
        "ALT Education 8.1" => :alt_8,
        "ALT Workstation 8.1" => :alt_8,
        "ALT Workstation K 8.1  (Centaurea Ruthenica)" => :alt_8,
        "ALT Linux p8 (Hypericum)" => :alt_8,

        "ALT Sisyphus (unstable) (sisyphus)" => :alt,
        "ALT Linux Sisyphus (unstable)" => :alt,
        "ALT Linux 6.0.1 Spt  (separator)" => :alt,
        "ALT Linux 7.0.5 School Master" => :alt,
        "ALT starter kit (Hypericum)" => :alt,

        "ALT" => :alt,
        "Simply" => :alt,
      }.each do |str, expected|
        it "returns #{expected} for #{str} in /etc/altlinux-release" do
          comm.stub_command("test -f /etc/os-release", exit_code: 1)
          comm.stub_command("cat /etc/altlinux-release", stdout: str)
          expect(cap.flavor(machine)).to be(expected)
        end
      end
    end

    context "with /etc/os-release file" do
      {
        [ "NAME=\"Sisyphus\"", "VERSION_ID=20161130" ] => :alt,

        [ "NAME=\"ALT Education\"", "VERSION_ID=8.1" ] => :alt_8,
        [ "NAME=\"ALT Server\"", "VERSION_ID=8.1" ] => :alt_8,
        [ "NAME=\"ALT SPServer\"", "VERSION_ID=8.0" ] => :alt_8,
        [ "NAME=\"starter kit\"", "VERSION_ID=p8" ] => :alt_8,
        [ "NAME=\"ALT Linux\"", "VERSION_ID=8.0.0" ] => :alt_8,
        [ "NAME=\"Simply Linux\"", "VERSION_ID=7.95.0" ] => :alt_8,

        [ "NAME=\"ALT Linux\"", "VERSION_ID=7.0.5" ] => :alt_7,
        [ "NAME=\"School Junior\"", "VERSION_ID=7.0.5" ] => :alt_7,
      }.each do |strs, expected|
        it "returns #{expected} for #{strs[0]} and #{strs[1]} in /etc/os-release" do
          comm.stub_command("test -f /etc/os-release", exit_code: 0)
          comm.stub_command("grep NAME /etc/os-release", stdout: strs[0])
          comm.stub_command("grep VERSION_ID /etc/os-release", stdout: strs[1])
          expect(cap.flavor(machine)).to be(expected)
        end
      end
    end
  end
end
