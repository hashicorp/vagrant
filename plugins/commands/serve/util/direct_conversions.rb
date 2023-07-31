# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# Patch things to produce proto messages
require "pathname"
require "securerandom"
require "google/protobuf/wrappers_pb"
require "google/protobuf/well_known_types"

PROTO_LOGGER = Log4r::Logger.new("vagrant::protologger")

# Default proto mapping
class Object
  def self.to_proto
    Hashicorp::Vagrant::Sdk::Args::Class.new(name: name)
  end

  def to_any
    pro = to_proto
    begin
      Google::Protobuf::Any.pack(pro)
    rescue
      PROTO_LOGGER.warn("failed to any this type: #{self.class} value: #{self}")
      raise
    end
  end

  def to_proto
    begin
      klass = self.class.to_proto
      data = Hash.new.tap do |h|
        instance_variables.each do |v|
          h[v.to_s.sub('@', '')] = instance_variable_get(v)
        end
      end

      entries = data.map do |k, v|
        Hashicorp::Vagrant::Sdk::Args::HashEntry.new(
          key: k.to_any,
          value: v.to_any,
        )
      end.compact
      Hashicorp::Vagrant::Sdk::Config::RawRubyValue.new(
        source: klass,
        data: Hashicorp::Vagrant::Sdk::Args::Hash.new(entries: entries)
      )
    end
  rescue => err
    PROTO_LOGGER.warn("failed to proto #{self.class} | reason: #{err}")
    raise
  end
end

# Base types
class Array
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Array.new(
      list: map(&:to_any)
    )
  end
end

class FalseClass
  def to_proto
    Google::Protobuf::BoolValue.new(value: false)
  end
end

class Float
  def to_proto
    Google::Protobuf::FloatValue.new(value: self)
  end
end

class Hash
  def to_proto
    entries = map do |k, v|
      Hashicorp::Vagrant::Sdk::Args::HashEntry.new(
        key: k.to_any,
        value: v.to_any,
      )
    end
    Hashicorp::Vagrant::Sdk::Args::Hash.new(entries: entries)
  end
end

class Integer
  def to_proto
    Google::Protobuf::Int64Value.new(value: self)
  end
end

class NilClass
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Null.new
  end
end

class Pathname
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Path.new(
      path: to_s
    )
  end
end

class Proc
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::ProcRef.new(
      id: VagrantPlugins::CommandServe::Mappers::ProcRegistry.instance.register(self)
    )
  end
end

class Range
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Range.new(start: first, end: last)
  end
end

class Set
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Set.new(list: to_a.to_proto)
  end
end

class String
  def to_proto
    Google::Protobuf::StringValue.new(value: to_s)
  end
end

class Symbol
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Symbol.new(str: to_s)
  end
end

class TrueClass
  def to_proto
    Google::Protobuf::BoolValue.new(value: true)
  end
end

# Complex types
class Vagrant::Plugin::V2::Config
  def to_proto
    data = Hash.new.tap do |h|
      instance_variables.each do |v|
        h[v.to_s.sub('@', '')] = instance_variable_get(v)
      end
    end

    # Include a unique identifier for this configuration instance. This
    # will allow us to identifier it later when it is decoded.
    if !data.key?("_vagrant_config_identifier")
      data["_vagrant_config_identifier"] = SecureRandom.uuid
    end

    entries = data.map do |k, v|
      Hashicorp::Vagrant::Sdk::Args::HashEntry.new(
        key: k.to_any,
        value: v.to_any,
      )
    end
    Hashicorp::Vagrant::Sdk::Args::ConfigData.new(
      data: Hashicorp::Vagrant::Sdk::Args::Hash.new(entries: entries),
      source: self.class.to_proto,
    )
  end
end

class Vagrant::Config::V2::Root
  def to_proto
    __internal_state["keys"].to_proto
  end
end

class VagrantPlugins::CommandServe::Type::CommunicatorCommandArguments
  def to_proto
    Hashicorp::Vagrant::Sdk::Communicator::Command.new(command: value)
  end
end

class VagrantPlugins::CommandServe::Type::CommandInfo
  def to_proto
    flags = info.flags.map do |f|
      Vagrant::Hashicorp::Sdk::Command::Flag.new(
        long_name: f.long_name,
        short_name: f.short_name,
        description: f.description,
        default_value: f.default_value,
        type: f.type == :BOOL ? Vagrant::Hashicorp::Sdk::Command::Flag::Type::BOOL :
          Hashicorp::Vagrant::Sdk::Command::Flag::Type::STRING
      )
    end
    subcommands = info.subcommands.map do |s_info|
      converter(s_info)
    end
    Hashicorp::Vagrant::Sdk::Command::CommandInfo.new(
      name: info.name,
      help: info.help,
      synopsis: info.synopsis,
      flags: flags,
      subcommands: subcommands,
      primary: info.primary,
    )
  end
end

class VagrantPlugins::CommandServe::Type::Direct
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Direct.new(
      arguments: value.to_proto
    )
  end
end

class VagrantPlugins::CommandServe::Type::Duration
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Duration.new(
      duration: value
    )
  end
end

class VagrantPlugins::CommandServe::Type::Folders
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Folders.new(
      folders: value.to_proto
    )
  end
end

class VagrantPlugins::CommandServe::Type::Options
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::Options.new(
      options: value.to_proto
    )
  end
end

class Log4r::Logger
  def to_proto
    Hashicorp::Vagrant::Sdk::Args::RubyLogger.new(name: fullname)
  end
end

# Proto conversions
class Google::Protobuf::Any
  def to_ruby
    _vagrant_unany(self).to_ruby
  end
end

module Google::Protobuf::MessageExts
  def to_ruby
    return value if self.respond_to?(:value)

    raise NotImplementedError,
          "#{self.class}#to_ruby has not been implemented"
  end

  # Convert Any proto message to actual message type
  #
  # @param any [Google::Protobuf::Any]
  # @return [Google::Protobuf::MessageExts]
  def _vagrant_unany(any)
    type = _vagrant_find_type(any.type_name.split("/").last.to_s)
    any.unpack(type)
  end

  # Get const from name
  #
  # @param name [String]
  # @return [Class]
  def _vagrant_find_type(name)
    parent_module_options = []
    name.to_s.split(".").inject(Object) { |memo, n|
      c = memo.constants.detect { |mc| mc.to_s.downcase == n.to_s.downcase }
      if c.nil?
        parent_module_options.delete(memo)
        parent_module_options.each do |pm|
          c = pm.constants.detect { |mc| mc.to_s.downcase == n.to_s.downcase }
          if !c.nil?
            memo = pm
            break
          end
        end
      end

      raise NameError,
            "Failed to find constant for `#{name}'" if c.nil?

      parent_module_options = memo.constants.select {
        |mc| mc.to_s.downcase == n.to_s.downcase
      }.map {
        |mc| memo.const_get(mc)
      }
      memo.const_get(c)
    }
  end

  def _vagrant_load_client(klass)
    raise TypeError,
          "Proto is not a valid client message type (#{self.class})" if
      !respond_to?(:addr)

    cid = "client+" + addr.to_s
    return VagrantPlugins::CommandServe.cache.get(cid) if
      VagrantPlugins::CommandServe.cache.registered?(cid)

    v = klass.load(self, broker: VagrantPlugins::CommandServe.broker)
    VagrantPlugins::CommandServe.cache.register(cid, v)
    v
  end
end

class Hashicorp::Vagrant::Sdk::Args::Array
  def to_ruby
    list.map { |a|
      val = _vagrant_unany(a).to_ruby
      val.is_a?(VagrantPlugins::CommandServe::Type) ? val.value : val
    }
  end
end

class Hashicorp::Vagrant::Sdk::Args::BoxMetadata
  # TODO(spox): should this be returning a box metadata instance instead of client?
  def to_ruby
    _vagrant_load_client(VagrantPlugins::CommandServe::Client::BoxMetadata)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Class
  def to_ruby
    if name.to_s.empty?
      raise NameError,
            "No name defined for for class"
    end
    name.to_s.split("::").inject(Object) { |memo, n|
      c = memo.constants.detect { |mc| mc.to_s.downcase == n.to_s.downcase }
      raise NameError,
            "Failed to find constant for `#{name}'" if c.nil?
      memo.const_get(c)
    }
  end
end

class Hashicorp::Vagrant::Sdk::Args::CorePluginManager
  def to_ruby
    _vagrant_load_client(VagrantPlugins::CommandServe::Client::CorePluginManager)
  end
end

class Hashicorp::Vagrant::Sdk::Args::ConfigData
  def to_ruby
    base_klass = source.to_ruby
    if [0, -1].include?(base_klass.instance_method(:initialize).arity)
      klass = base_klass
    else
      klass = Class.new(base_klass)
      klass.class_eval("
              def self.to_proto
                #{base_klass.name}.to_proto
              end
              def self.class
                #{base_klass.name}
              end
              def initialize
              end
            ")
    end
    instance = klass.new
    d = data.to_ruby

    # Since we are restoring the config, if the config this
    # represents was already finalized we finalize it first
    # before we inject the instance variables to get as close
    # to the correct original state as possible
    if d.key?("__finalized")
      instance.finalize!
      instance._finalize!
    end

    # Now set our data into the instance
    d.each_pair do |k, v|
      instance.instance_variable_set("@#{k}", v)
    end

    instance
  end
end

class Hashicorp::Vagrant::Sdk::Args::Direct
  def to_ruby
    VagrantPlugins::CommandServe::Type::Direct.new(
      arguments: arguments.map { |arg|
        val = arg.to_ruby
        val.is_a?(VagrantPlugins::CommandServe::Type) ? val.value : val
      }
    )
  end
end

class Hashicorp::Vagrant::Sdk::Args::Folders
  def to_ruby
    VagrantPlugins::CommandServe::Type::Folders.new(value: folders.to_ruby)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Guest
  def to_ruby
    _vagrant_load_client(VagrantPlugins::CommandServe::Client::Guest)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Hash
  def to_ruby
    data = Hash.new
    entries.each do |e|
      key = _vagrant_unany(e.key).to_ruby
      value = _vagrant_unany(e.value).to_ruby
      data[key] = value.is_a?(VagrantPlugins::CommandServe::Type) ? value.value : value
    end

    data
  end
end

class Hashicorp::Vagrant::Sdk::Args::Host
  def to_ruby
    client = _vagrant_load_client(VagrantPlugins::CommandServe::Client::Host)
    Vagrant::Host.new(client, nil, Vagrant.plugin("2").local_manager.host_capabilities)
  end
end

class Hashicorp::Vagrant::Sdk::Args::NamedCapability
  def to_ruby
    capability.to_s.to_sym
  end
end

class Hashicorp::Vagrant::Sdk::Args::Null
  def to_ruby
    nil
  end
end

class Hashicorp::Vagrant::Sdk::Args::Options
  def to_ruby
    VagrantPlugins::CommandServe::Type::Options.new(value: options.to_ruby)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Path
  def to_ruby
    Pathname.new(path.to_s)
  end
end

class Hashicorp::Vagrant::Sdk::Args::ProcRef
  def to_ruby
    VagrantPlugins::CommandServe::Mappers::ProcRegistry.instance.fetch(id)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Project
  def to_ruby
    cid = "environment"+addr.to_s
    return VagrantPlugins::CommandServe.cache.get(cid) if
      VagrantPlugins::CommandServe.cache.registered?(cid)

    client = _vagrant_load_client(VagrantPlugins::CommandServe::Client::Project)
    ui = client.ui.to_ui

    env = Vagrant::Environment.new(client: client, ui: ui)
    VagrantPlugins::CommandServe.cache.register(cid, env)
    env
  end
end

class Hashicorp::Vagrant::Sdk::Args::Provisioner
  def to_ruby
    _vagrant_load_client(VagrantPlugins::CommandServe::Client::Provisioner)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Provider
  def to_ruby
    _vagrant_load_client(VagrantPlugins::CommandServe::Client::Provider)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Range
  def to_ruby
    Range.new(self.start, self.end)
  end
end

class Hashicorp::Vagrant::Sdk::Config::RawRubyValue
  def to_ruby
    base_klass = source.to_ruby
    if [0, -1].include?(base_klass.instance_method(:initialize).arity)
      klass = base_klass
    else
      klass = Class.new(base_klass)
      klass.class_eval("
              def self.class
                #{base_klass.name}
              end
              def initialize
              end
            ")
    end

    instance = klass.new
    d = data.to_ruby

    d.each_pair do |k, v|
      instance.instance_variable_set("@#{k}", v)
    end

    instance
  end
end

class Hashicorp::Vagrant::Sdk::Args::RubyLogger
  def to_ruby
    Log4r::Logger.new(name)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Set
  def to_ruby
    ::Set.new(list.to_ruby)
  end
end

class Hashicorp::Vagrant::Sdk::Args::StateBag
  def to_ruby
    _vagrant_load_client(VagrantPlugins::CommandServe::Client::StateBag)
  end
end

class Hashicorp::Vagrant::Sdk::Args::SyncedFolder
  def to_ruby
    cid = "syncedfolder+" + addr.to_s
    return VagrantPlugins::CommandServe.cache.get(cid) if
      VagrantPlugins::CommandServe.cache.registered?(cid)

    client = _vagrant_load_client(VagrantPlugins::CommandServe::Client::SyncedFolder)
    fld = Vagrant::Plugin::Remote::SyncedFolder.new(client: client)
    VagrantPlugins::CommandServe.cache.register(cid, fld)
    fld
  end
end

class Hashicorp::Vagrant::Sdk::Args::Symbol
  def to_ruby
    str.to_sym
  end
end

class Hashicorp::Vagrant::Sdk::Args::Target
  def to_ruby
    cid = "machine+" + addr.to_s
    return VagrantPlugins::CommandServe.cache.get(cid) if
      VagrantPlugins::CommandServe.cache.registered?(cid)

    client = _vagrant_load_client(VagrantPlugins::CommandServe::Client::Target)
    env = client.project.to_ruby
    machine = env.machine(client.name.to_sym, client.provider_name.to_sym)
    VagrantPlugins::CommandServe.cache.register(cid, machine)
    machine
  end
end

class Hashicorp::Vagrant::Sdk::Args::Target::Machine
  def to_ruby
    cid = "machine+" + addr.to_s
    return VagrantPlugins::CommandServe.cache.get(cid) if
      VagrantPlugins::CommandServe.cache.registered?(cid)

    client = _vagrant_load_client(VagrantPlugins::CommandServe::Client::Target::Machine)
    m = Vagrant::Machine.new(client: client)
    VagrantPlugins::CommandServe.cache.register(cid, m)
    m
  end
end

class Hashicorp::Vagrant::Sdk::Args::Target::Machine::State
  def to_ruby
    Vagrant::MachineState.new(
      m.id.to_sym, m.short_description, m.long_description
    )
  end
end

class Hashicorp::Vagrant::Sdk::Args::TargetIndex
  def to_ruby
    _vagrant_load_client(VagrantPlugins::CommandServe::Client::TargetIndex)
  end
end

class Hashicorp::Vagrant::Sdk::Args::TimeDuration
  def to_ruby
    VagrantPlugins::CommandServe::Type::Duration.new(value: duration)
  end
end

class Hashicorp::Vagrant::Sdk::Args::TerminalUI
  def to_ruby
    client = _vagrant_load_client(VagrantPlugins::CommandServe::Client::Terminal)
    Vagrant::UI::Remote.new(client)
  end
end

class Hashicorp::Vagrant::Sdk::Args::Vagrantfile
  def to_ruby
    client = _vagrant_load_client(VagrantPlugins::CommandServe::Client::Vagrantfile)
    Vagrant::Vagrantfile.new(client: client)
  end
end

class Hashicorp::Vagrant::Sdk::Command::Arguments
  def to_ruby
    _args = args.to_a
    _flags = Hash.new.tap do |flgs|
      flags.each do |f|
        if f.type == :BOOL
          flgs[f.name] = f.bool
        else
          flgs[f.name] = f.string
        end
      end
    end
    VagrantPlugins::CommandServe::Type::CommandArguments.new(args: _args, flags: _flags)
  end
end

class Hashicorp::Vagrant::Sdk::Command::CommandInfo
  def to_ruby
    VagrantPlugins::CommandServe::Type::CommandInfo.new(
      name: name,
      help: help,
      synopsis: synopsis,
      primary: primary,
    ).tap do |c|
      flags.each do |f|
        c.add_flag(
          long_name: f.long_name,
          short_name: f.short_name,
          description: f.description,
          default_value: f.default_value,
          type: f.type,
        )
      end
      subcommands.each do |s_proto|
        c.add_subcommand(s_proto.to_ruby)
      end
    end
  end
end

class Hashicorp::Vagrant::Sdk::Communicator::Command
  def to_ruby
    VagrantPlugins::CommandServe::Type::CommunicatorCommandArguments.new(value: command)
  end
end
