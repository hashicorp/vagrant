require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/gentoo/network_systemd" do
  let(:template) { "guests/gentoo/network_systemd" }

  it "renders the template with a static ip" do
    result = Vagrant::Util::TemplateRenderer.render(template, networks: [{
      device:  "eth0",
      type:    "dhcp",
    }])
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      [Match]
      Name=eth0

      [Network]
      DHCP=yes
    EOH
  end

  it "renders the template with multiple ips" do
    result = Vagrant::Util::TemplateRenderer.render(template, networks: [{
      device:  "eth0",
      ip:      "1.1.1.1",
      netmask: "16",
    },{
      device:  "eth0",
      ip:      "1.1.2.2",
      netmask: "16",
    }])
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      [Match]
      Name=eth0

      [Network]
      Address=1.1.1.1/16
      Address=1.1.2.2/16
    EOH
  end

  it "renders the template with a static ip" do
    result = Vagrant::Util::TemplateRenderer.render(template, networks: [{
      device:  "eth0",
      ip:      "1.1.1.1",
      netmask: "16",
    }])
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      [Match]
      Name=eth0

      [Network]
      Address=1.1.1.1/16
    EOH
  end

  it "includes the gateway" do
    result = Vagrant::Util::TemplateRenderer.render(template, networks: [{
      device:  "eth0",
      ip:      "1.1.1.1",
      netmask: "16",
      gateway: "1.2.3.4",
    }])
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      [Match]
      Name=eth0

      [Network]
      Address=1.1.1.1/16
      Gateway=1.2.3.4
    EOH
  end
end
