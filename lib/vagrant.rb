libdir = File.dirname(__FILE__)
$:.unshift(libdir)
PROJECT_ROOT = File.join(libdir, '..')

require 'ftools'
require 'json'
require 'pathname'
require 'logger'
require 'virtualbox'
require 'net/ssh'
require 'net/scp'
require 'ping'
require 'vagrant/busy'
require 'vagrant/util'
require 'vagrant/config'
require 'vagrant/env'
require 'vagrant/provisioning'
require 'vagrant/ssh'
require 'vagrant/vm'

# TODO: Make this configurable
log_output = ENV['VAGRANT_ENV'] == 'test' ? nil : STDOUT
VAGRANT_LOGGER = Vagrant::Logger.new(log_output)
Vagrant::Env.load! unless ENV['VAGRANT_ENV'] == 'test'
