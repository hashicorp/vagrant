require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/arch/network_dhcp" do
  let(:template) { "guests/arch/network_dhcp" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device: "eth1",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      Description='A basic dhcp ethernet connection'
      Interface=eth1
      Connection=ethernet
      IP=dhcp
    EOH
  end
end
