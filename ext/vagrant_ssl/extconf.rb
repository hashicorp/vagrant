#!/usr/bin/env ruby

require "mkmf"

if have_header("openssl/opensslv.h")
  if ENV["LDFLAGS"]
    append_ldflags(ENV["LDFLAGS"].split(" "))
  end
  append_ldflags(["-lssl"])
  create_makefile("vagrant_ssl")
else
  # If the header file isn't found, just create a dummy
  # Makefile and stub the library to make it a noop
  File.open("Makefile", "wb") do |f|
    f.write(dummy_makefile(__dir__).join("\n"))
  end
  FileUtils.touch("vagrant_ssl.so")
end
