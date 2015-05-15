require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/freebsd/network_dhcp" do
  let(:template) { "guests/freebsd/network_dhcp" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, ifname: "vtneten0")
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      #VAGRANT-BEGIN
      ifconfig_vtneten0="DHCP"
      #VAGRANT-END
    EOH
  end
end
