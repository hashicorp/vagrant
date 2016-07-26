require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/freebsd/network_dhcp" do
  let(:template) { "guests/freebsd/network_dhcp" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device: "eth1",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      #VAGRANT-BEGIN
      ifconfig_eth1="DHCP"
      synchronous_dhclient="YES"
      #VAGRANT-END
    EOH
  end
end
