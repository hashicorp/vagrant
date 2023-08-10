#!/usr/bin/env ruby
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1


require "mkmf"
require "shellwords"

# If extra flags are included via the environment, append them
append_cflags(Shellwords.shellwords(ENV["CFLAGS"])) if ENV["CFLAGS"]
append_cppflags(Shellwords.shellwords(ENV["CPPFLAGS"])) if ENV["CPPFLAGS"]
append_ldflags(Shellwords.shellwords(ENV["LDFLAGS"])) if ENV["LDFLAGS"]

if have_header("openssl/opensslv.h")
  append_ldflags(["-lssl", "-lcrypto"])
  create_makefile("vagrant/vagrant_ssl")
else
  # If the header file isn't found, just create a dummy
  # Makefile and stub the library to make it a noop
  File.open("Makefile", "wb") do |f|
    f.write(dummy_makefile(__dir__).join("\n"))
  end
  FileUtils.touch("vagrant_ssl.so")
end
