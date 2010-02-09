libdir = File.dirname(__FILE__)
$:.unshift(libdir)
PROJECT_ROOT = File.join(libdir, '..')

require 'ftools'
require 'pathname'
require 'logger'
require 'virtualbox'
require 'net/ssh'
require 'ping'
require 'hobo/busy'
require 'hobo/util'
require 'hobo/config'
require 'hobo/env'
require 'hobo/provisioning'
require 'hobo/ssh'
require 'hobo/vm'

# TODO: Make this configurable
log_output = ENV['HOBO_ENV'] == 'test' ? nil : STDOUT
HOBO_LOGGER = Hobo::Logger.new(log_output)
Hobo::Env.load! unless ENV['HOBO_ENV'] == 'test'
