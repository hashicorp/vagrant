require_relative "../../../../base"

describe VagrantPlugins::HyperV::Action::Import do
  include_context "unit"

  let(:box) { double("box")}
  let(:box_collection) { double("box_collection")}
  let(:powershell) { double("powershell") }
  let(:machine) {double("machine")}
  let(:env) {{ 
    machine: machine,
    ui: Vagrant::UI::Silent.new
  }}
  let(:app)    { lambda { |*args| }}
  let(:driver) {double("driver")}
  let(:provider) { double("provider")}
  let(:box_dir) { isolated_environment.box3('default', '1.0',  :hyperv) }
  let(:image_drive) { box_dir.join("Virtual Hard Disks") }
  before do
    vm_dir = box_dir.join("Virtual Machines")
    vm_dir.mkpath
    image_drive.mkpath
    vm_dir.join("vm.xml").open("w")
    @import_path = "bad val"
    allow(driver).to receive(:import){ |arg| @import_path = arg[:image_path]}
    allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
    allow(Vagrant::Util::Platform).to receive(:windows_admin?).and_return(true)
    stub_const("Vagrant::Util::PowerShell", powershell)
    powershell.stub(available?: true)
    machine.stub(box: box)
    box.stub(directory: box_dir)
    provider.stub(driver: driver)
    machine.stub(provider: provider)
    machine.stub(:id=)
    driver.stub(execute: [{:name => 'switch'}])
    machine.stub(data_dir: Pathname("/data_dir"))
    FileUtils.stub(:cp)
  end
  
  subject { described_class.new(app, env) }

  it "parses the vhdx file" do
    image_drive.join("disk.vhdx").open("w")
    
    subject.call(env)

    expect(@import_path).to eq("\\data_dir\\disk.vhdx")
  end
  it "parses the vhd file" do
    image_drive.join("disk.vhd").open("w")
    
    subject.call(env)

    expect(@import_path).to eq("\\data_dir\\disk.vhd")
  end  
end
