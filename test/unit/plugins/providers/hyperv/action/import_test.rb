require_relative "../../../../base"

describe VagrantPlugins::HyperV::Action::Import do
  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end
  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      m.provider.stub(driver: driver)
    end
  end
  let(:app)    { lambda { |*args| }}
  
  before do
    box_dir = iso_env.box2(:dummy, "hyperv")
    vm_dir = box_dir.join("Virtual Machines")
    @hd_dir = box_dir.join("Virtual Hard Disks")
    vm_dir.mkpath
    @hd_dir.mkpath
    vm_dir.join("vm.xml").open("w")
  end
  
  subject { described_class.new(app, iso_env) }


  it "parses the vhd file" do
    @hd_dir.join("disk.vhdx").open("w")

    subject.call(iso_env)

    expect(File).to exist(machine.data_dir.join('disk.vhdx'))
  end
end
