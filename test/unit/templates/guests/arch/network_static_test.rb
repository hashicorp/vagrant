require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/arch/network_static" do
  let(:template) { "guests/arch/network_static" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device: "en0",
      ip:     "1.1.1.1",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      Connection=ethernet
      Description='A basic static ethernet connection'
      Interface=en0
      IP=static
      Address=('1.1.1.1/24')
    EOH
  end

  it "includes the gateway" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device:  "en0",
      ip:      "1.1.1.1",
      gateway: "1.2.3.4",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      Connection=ethernet
      Description='A basic static ethernet connection'
      Interface=en0
      IP=static
      Address=('1.1.1.1/24')
      Gateway='1.2.3.4'
    EOH
  end
end
