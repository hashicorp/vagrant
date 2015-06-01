require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/netbsd/network_static" do
  let(:template) { "guests/netbsd/network_static" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      interface: "en0",
      ip:        "1.1.1.1",
      netmask:   "255.255.0.0",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      #VAGRANT-BEGIN
      ifconfig_wmen0="media autoselect up;inet 1.1.1.1 netmask 255.255.0.0"
      #VAGRANT-END
    EOH
  end
end
