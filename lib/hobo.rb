libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
PROJECT_ROOT = File.join(libdir, '..')

require 'ostruct'
require 'ftools'
require 'logger'
require 'hobo/config'
require 'hobo/env'
require 'hobo/ssh'

# TODO: Make this configurable
HOBO_LOGGER = Logger.new(STDOUT)
Hobo::Env.load_config
