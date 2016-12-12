require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/freebsd/network_static" do
  let(:template) { "guests/freebsd/network_static" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device:  "eth1",
      ip:      "1.1.1.1",
      netmask: "255.255.0.0",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      #VAGRANT-BEGIN
      ifconfig_eth1="inet 1.1.1.1 netmask 255.255.0.0"
      #VAGRANT-END
    EOH
  end

  it "includes the gateway" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device:  "eth1",
      ip:      "1.1.1.1",
      netmask: "255.255.0.0",
      gateway: "1.2.3.4",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      #VAGRANT-BEGIN
      ifconfig_eth1="inet 1.1.1.1 netmask 255.255.0.0"
      default_router="1.2.3.4"
      #VAGRANT-END
    EOH
  end
end
