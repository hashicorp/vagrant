# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/arch/systemd_networkd/network_static" do
  let(:template) { "guests/arch/systemd_networkd/network_static" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device:  "eth1",
      ip:      "1.1.1.1",
      netmask: "24",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      [Match]
      Name=eth1

      [Network]
      Description=A basic static ethernet connection
      Address=1.1.1.1/24
    EOH
  end

  it "includes the gateway" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device:  "eth1",
      ip:      "1.1.1.1",
      gateway: "1.2.3.4",
      netmask: "24",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      [Match]
      Name=eth1

      [Network]
      Description=A basic static ethernet connection
      Address=1.1.1.1/24
      Gateway=1.2.3.4
    EOH
  end
end
