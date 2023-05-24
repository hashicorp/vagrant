#!/usr/bin/env ruby

require "mkmf"

if have_header("openssl/opensslv.h")
  if ENV["LDFLAGS"]
    append_ldflags(ENV["LDFLAGS"].split(" "))
  end
  append_ldflags(["-lssl"])
  create_makefile("vagrant_ssl")
end
