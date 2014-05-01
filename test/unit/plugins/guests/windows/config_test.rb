require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/guests/windows/config")

describe VagrantPlugins::GuestWindows::Config do
  let(:machine) { double("machine") }

  subject { described_class.new }

  it "is valid by default" do
    subject.finalize!
    result = subject.validate(machine)
    expect(result["Windows Guest"]).to be_empty
  end

  describe "default values" do
    before { subject.finalize! }
    its("set_work_network") { should == false }
  end

  describe "attributes" do
    [:set_work_network].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=".to_sym, 10)
        subject.finalize!
        subject.send(attribute).should == 10
      end

      it "should return error #{attribute} if nil" do
        subject.send("#{attribute}=".to_sym, nil)
        subject.finalize!
        result = subject.validate(machine)
        expect(result["Windows Guest"]).to include("windows.#{attribute} cannot be nil.")
      end
    end
  end

end
