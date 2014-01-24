require "pathname"

module Vagrant
  # This returns whether or not 3rd party plugins should be loaded.
  #
  # @return [Boolean]
  def self.plugins_enabled?
    !ENV["VAGRANT_NO_PLUGINS"]
  end

  # Returns the URL prefix to the server.
  #
  # @return [String]
  def self.server_url
    # TODO: default
    ENV["VAGRANT_SERVER_URL"]
  end

  # The source root is the path to the root directory of the Vagrant source.
  #
  # @return [Pathname]
  def self.source_root
    @source_root ||= Pathname.new(File.expand_path('../../../', __FILE__))
  end

  # This returns the path to the ~/.vagrant.d folder where Vagrant's
  # per-user state is stored.
  #
  # @return [Pathname]
  def self.user_data_path
    # Use user spcified env var if available
    path = ENV["VAGRANT_HOME"]

    # On Windows, we default ot the USERPROFILE directory if it
    # is available. This is more compatible with Cygwin and sharing
    # the home directory across shells.
    if !path && ENV["USERPROFILE"]
      path = "#{ENV["USERPROFILE"]}/.vagrant.d"
    end

    # Fallback to the default
    path ||= "~/.vagrant.d"

    Pathname.new(path).expand_path
  end
end
