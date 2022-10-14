require "rexml"
require File.expand_path("../version_6_1", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 7.0.x
      class Version_7_0 < Version_6_1
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_7_0")
        end

        # The initial VirtualBox 7.0 release has an issue with displaying port
        # forward information. When a single port forward is defined, the forwarding
        # information can be found in the `showvminfo` output. Once more than a
        # single port forward is defined, no forwarding information is provided
        # in the `showvminfo` output. To work around this we grab the VM configuration
        # file from the `showvminfo` output and extract the port forward information
        # from there instead.
        def read_forwarded_ports(uuid=nil, active_only=false)
          @version ||= Meta.new.version

          # Only use this override for the 7.0.0 release. If it is still broken
          # on the 7.0.1 release we can modify the version check.
          return super if @version != "7.0.0"

          uuid ||= @uuid

          @logger.debug("read_forward_ports: uuid=#{uuid} active_only=#{active_only}")

          results = []

          info = execute("showvminfo", uuid, "--machinereadable", retryable: true)
          result = info.match(/CfgFile="(?<path>.+?)"/)
          if result.nil?
            raise Vagrant::Errors::VirtualBoxConfigNotFound,
                  uuid: uuid
          end

          File.open(result[:path], "r") do |f|
            doc = REXML::Document.new(f)
            networks = REXML::XPath.each(doc.root, "//Adapter")
            networks.each do |net|
              REXML::XPath.each(doc.root, net.xpath + "/NAT/Forwarding") do |fwd|
                # Result Array values:
                # [NIC Slot, Name, Host Port, Guest Port, Host IP]
                result = [
                  net.attribute("slot").value.to_i + 1,
                  fwd.attribute("name")&.value.to_s,
                  fwd.attribute("hostport")&.value.to_i,
                  fwd.attribute("guestport")&.value.to_i,
                  fwd.attribute("hostip")&.value.to_s
                ]
                @logger.debug(" - #{result.inspect}")
                results << result
              end
            end
          end

          results
        end
      end
    end
  end
end
