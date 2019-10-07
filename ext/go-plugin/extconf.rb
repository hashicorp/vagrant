lib = File.expand_path('./../../../lib', File.expand_path(__FILE__))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'mkmf'
require 'time'

find_executable('go')

go_version = /go version go(\d+\.\d+)/.match(`go version`).captures.first
raise "'go' version >=1.5.0 is required, found go #{go_version}" unless Gem::Dependency.new('', '>=1.5.0').match?('', go_version)

makefile = "Makefile"
makefile_content = <<MFEND
NAME := #{File.basename(File.dirname(File.expand_path(__FILE__)))}
BINARY := ${NAME}.so

V = 0
Q1 = $(V:1=)
Q = $(Q1:0=@)
ECHO1 = $(V:1=@:)
ECHO = $(ECHO1:0=@echo)

SOURCEDIR=.
SOURCES := $(shell find $(SOURCEDIR) -maxdepth 0 -name '*.go')

VERSION=1.0
BUILD_DATE=#{Time.now.iso8601}

cflags= $(optflags) $(warnflags)
optflags= -O3 -fno-fast-math
warnflags= -Wall -Wextra -Wno-unused-parameter -Wno-parentheses -Wno-long-long -Wno-missing-field-initializers -Wunused-variable -Wpointer-arith -Wwrite-strings -Wimplicit-function-declaration -Wdiv-by-zero -Wdeprecated-declarations
CCDLFLAGS= -fno-common
INCFLAGS= -I#{RbConfig::CONFIG['rubyhdrdir']}/ -I#{RbConfig::CONFIG['rubyarchhdrdir']}/ -I$(SOURCEDIR)
CFLAGS= $(CCDLFLAGS) $(cflags) -fno-common -pipe $(INCFLAGS)

LDFLAGS=-L#{RbConfig::CONFIG['libdir']} #{RbConfig::CONFIG['LIBRUBYARG']}

.DEFAULT_GOAL := $(BINARY)

.PHONY: help
help:
  ${ECHO} ${VERSION}
  ${ECHO} ${BUILD_DATE}

all:
  make clean
  $(BINARY)

$(BINARY): $(SOURCES)
  CGO_CFLAGS="${CFLAGS}" CGO_LDFLAGS="${LDFLAGS}" go build -buildmode=c-shared -o ${BINARY} #{File.dirname(__FILE__)}/../../ext/${NAME}/

.PHONY: install
install:
  # go install ${LDFLAGS} ./...

.PHONY: clean
clean:
  if [ -f ${BINARY} ] ; then rm ${BINARY} ; fi
  if [ -f lib/${BINARY} ] ; then rm lib/${BINARY} ; fi
MFEND

puts "creating Makefile"
File.open(makefile, 'w') do |f|
  f.write(makefile_content.gsub!(/(?:^|\G) {2}/m,"\t"))
end


$makefile_created = true
