# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

# This allows for effective monkey patching of the MakeMakefile
# module when building gem extensions. When gem extensions are
# built, the extconf.rb file is executed as a separate process.
# To support monkey patching the MakeMakefile module, the ruby
# executable path is adjusted to add a custom load path allowing
# a customized mkmf.rb file to load the proper mkmf.rb file, and
# then applying the proper patches.
if Gem.win_platform?
  Gem.class_eval do
    class << self
      def vagrant_ruby
        cmd = ruby_ruby
        "#{cmd} -I\"#{Vagrant.source_root.join("lib/vagrant/patches/builder")}\""
      end

      alias_method :ruby_ruby, :ruby
      alias_method :ruby, :vagrant_ruby
    end
  end
end
