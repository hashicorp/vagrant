# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant"

module VagrantPlugins
  module GuestOpenWrt
    class Plugin < Vagrant.plugin("2")
      name "OpenWrt guest"
      description "OpenWrt guest support."

      guest(:openwrt, :linux) do
        require_relative "guest"
        Guest
      end

      guest_capability(:openwrt, :insert_public_key) do
        require_relative "cap/insert_public_key"
        Cap::InsertPublicKey
      end

      guest_capability(:openwrt, :remove_public_key) do
        require_relative "cap/remove_public_key"
        Cap::RemovePublicKey
      end

      guest_capability(:openwrt, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:openwrt, :rsync_installed) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openwrt, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openwrt, :rsync_pre) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openwrt, :rsync_command) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openwrt, :rsync_post) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openwrt, :halt) do
        require_relative "cap/halt"
        Cap::Halt
      end
    end
  end
end

