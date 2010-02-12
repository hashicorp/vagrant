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
require 'tarruby'
require 'fileutils'
require 'vagrant/busy'
require 'vagrant/util'
require 'vagrant/commands'
require 'vagrant/config'
require 'vagrant/env'
require 'vagrant/provisioning'
require 'vagrant/ssh'
require 'vagrant/vm'
