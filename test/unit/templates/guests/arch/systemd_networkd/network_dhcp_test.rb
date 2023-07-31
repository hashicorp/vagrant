# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/arch/systemd_networkd/network_dhcp" do
  let(:template) { "guests/arch/systemd_networkd/network_dhcp" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device: "eth1",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      [Match]
      Name=eth1

      [Network]
      Description=A basic DHCP ethernet connection
      DHCP=ipv4
    EOH
  end
end
