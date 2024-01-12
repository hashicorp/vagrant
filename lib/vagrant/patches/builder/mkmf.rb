# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

# This custom mkmf.rb file is used on Windows platforms
# to handle common path related build failures where
# a space is included in the path. The default installation
# location being in Program Files results in most many
# extensions failing to build. These patches will attempt
# to find unquoted paths in flags and quote them prior to
# usage.

# Start with locating the real mkmf.rb file and
# loading it
mkmf_paths = $LOAD_PATH.find_all { |x|
  !x.start_with?(__dir__) &&
  File.exist?(File.join(x, "mkmf.rb"))
}.uniq

# At this point the path collection should only consist
# of a single entry. If there's more than one, load all
# of them but include a warning message that more than
# one was encountered. If none are found, then something
# bad is going on so just bail.
if mkmf_paths.size > 1
  $stderr.puts "WARNING: Multiple mkmf.rb files located: #{mkmf_paths.inspect}"
elsif mkmf_paths.empty?
  raise "Failed to locate mkmf.rb file"
end

mkmf_paths.each do |mpath|
  require File.join(mpath, "mkmf.rb")
end

# Attempt to detect and quote Windos paths found within
# the given string of flags
#
# @param [String] flags Compiler/linker flags
# @return [String] flags with paths quoted
def flag_cleaner(flags)
  parts = flags.split(" -")
  parts.map! do |p|
    if p !~ %r{[A-Za-z]:(/|\\)}
      next p
    elsif p =~ %r{"[A-Za-z]:(/|\\).+"$}
      next p
    end

    p.gsub(%r{([A-Za-z]:(/|\\).+)$}, '"\1"')
  end

  parts.join(" -")
end

# Check values defined for CFLAGS, CPPFLAGS, LDFLAGS,
# and INCFLAGS for unquoted Windows paths and quote
# them.
def clean_flags!
  $CFLAGS = flag_cleaner($CFLAGS)
  $CPPFLAGS = flag_cleaner($CPPFLAGS)
  $LDFLAGS = flag_cleaner($LDFLAGS)
  $INCFLAGS = flag_cleaner($INCFLAGS)
end

# Since mkmf loads the MakeMakefile module directly into the
# current scope, apply patches directly in the scope
def vagrant_create_makefile(*args)
  clean_flags!

  ruby_create_makefile(*args)
end
alias :ruby_create_makefile :create_makefile
alias :create_makefile :vagrant_create_makefile

def vagrant_append_cflags(*args)
  result = ruby_append_cflags(*args)
  clean_flags!
  result
end
alias :ruby_append_cflags :append_cflags
alias :append_cflags :vagrant_append_cflags

def vagrant_append_cppflags(*args)
  result = ruby_append_cppflags(*args)
  clean_flags!
  result
end
alias :ruby_append_cppflags :append_cppflags
alias :append_cppflags :vagrant_append_cppflags

def vagrant_append_ldflags(*args)
  result = ruby_append_ldflags(*args)
  clean_flags!
  result
end
alias :ruby_append_ldflags :append_ldflags
alias :append_ldflags :vagrant_append_ldflags

def vagrant_cc_config(*args)
  clean_flags!
  ruby_cc_config(*args)
end
alias :ruby_cc_config :cc_config
alias :cc_config :vagrant_cc_config

def vagrant_link_config(*args)
  clean_flags!
  ruby_link_config(*args)
end
alias :ruby_link_config :link_config
alias :link_config :vagrant_link_config

# Finally, always append the flags that Vagrant has
# defined via the environment
append_cflags(ENV["CFLAGS"]) if ENV["CFLAGS"]
append_cppflags(ENV["CPPFLAGS"]) if ENV["CPPFLAGS"]
append_ldflags(ENV["LDFLAGS"]) if ENV["LDFLAGS"]
