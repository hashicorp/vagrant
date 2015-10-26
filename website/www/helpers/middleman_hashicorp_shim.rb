# This file is a shim that mirrors the behavior or middleman-hashicorp without
# fully importing it. Vagrant is somewhat of a beast and cannot be easily
# updated due to older versions of bootstrap and javascript and whatnot.

require "open-uri"

class MiddlemanHashiCorpReleases
  RELEASES_URL = "https://releases.hashicorp.com".freeze

  class Build < Struct.new(:name, :version, :os, :arch, :url); end

  def self.fetch(product, version)
    url = "#{RELEASES_URL}/#{product}/#{version}/index.json"
    r = JSON.parse(open(url).string,
      create_additions: false,
      symbolize_names: true,
    )

    # Convert the builds into the following format:
    #
    #     {
    #       "os" => {
    #         "arch" => "https://download.url"
    #       }
    #     }
    #
    {}.tap do |h|
      r[:builds].each do |b|
        build = Build.new(*b.values_at(*Build.members))

        h[build.os] ||= {}
        h[build.os][build.arch] = build.url
      end
    end
  end
end

module MiddlemanHashiCorpHelpers
  #
  # Output an image that corresponds to the given operating system using the
  # vendored image icons.
  #
  # @return [String] (html)
  #
  def system_icon(name)
    image_tag("icons/icon_#{name.to_s.downcase}.png")
  end

  #
  # The formatted operating system name.
  #
  # @return [String]
  #
  def pretty_os(os)
    case os
    when /darwin/
      "Mac OS X"
    when /freebsd/
      "FreeBSD"
    when /openbsd/
      "OpenBSD"
    when /linux/
      "Linux"
    when /windows/
      "Windows"
    else
      os.capitalize
    end
  end

  #
  # The formatted architecture name.
  #
  # @return [String]
  #
  def pretty_arch(arch)
    case arch
    when /all/
      "Universal (32 and 64-bit)"
    when /686/, /386/
      "32-bit"
    when /86_64/, /amd64/
      "64-bit"
    else
      parts = arch.split("_")

      if parts.empty?
        raise "Could not determine pretty arch `#{arch}'!"
      end

      parts.last.capitalize
    end
  end

  #
  # Query the Bintray API to get the real product download versions.
  #
  # @return [Hash]
  #
  def product_versions
    MiddlemanHashiCorpReleases.fetch("vagrant", latest_version)
  end
end
