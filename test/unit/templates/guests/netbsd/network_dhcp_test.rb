require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/netbsd/network_dhcp" do
  let(:template) { "guests/netbsd/network_dhcp" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      interface: "en0",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      #VAGRANT-BEGIN
      ifconfig_wmen0=dhcp
      #VAGRANT-END
    EOH
  end
end
