require "vagrant"

def augment_cmd_class(cmd_cls)
  # Create a new anonymous class based on the command class
  # so we can modify the setup behavior
  klass = Class.new(cmd_cls)

  klass.class_eval do
    def subcommands
      @subcommands
    end

    def parse_options(opts)
      Thread.current.thread_variable_set(:command_options, opts)
      nil
    end
  end

  klass
end

def command_options_for(name, subcommands=[])
  plugin = Vagrant::Plugin::V2::Plugin.manager.commands[name.to_sym].to_a.first
  if !plugin
    raise "Failed to locate command plugin for: #{name}"
  end

  Vagrant::UI::Silent.class_eval do
    def info(message, *opts)
      Thread.current.thread_variable_set(:command_info, message)
      nil
    end
  end

  env = Vagrant::Environment.new()

  # Get the root command class
  klass = augment_cmd_class(plugin.call).new([], env)

  # Go through the subcommands, looking for the command we actually want
  subcommands.each do |cmd|
    cmd_cls = klass.subcommands[cmd.to_sym]
    klass = augment_cmd_class(cmd_cls).new([], env)
  end

  begin
    klass.execute
  rescue Vagrant::Errors::CLIInvalidUsage
    # This is expected since no args are being provided
  end

  options = Thread.current.thread_variable_get(:command_options)
  msg = Thread.current.thread_variable_get(:command_info)

  # Clean our option data out of the thread
  Thread.current.thread_variable_set(:command_options, nil)
  Thread.current.thread_variable_set(:command_info, nil)

  if !options.nil?
    return options
  elsif !msg.nil?
    return msg
  end
end

puts "getting help for status"
hlp = command_options_for("status", [])
puts hlp

# puts "\ngetting help for box"
# hlp = command_options_for("box", [])
# puts hlp

# puts "\ngetting help for box add"
# hlp = command_options_for("box", ["add"])
# puts hlp

# puts "\ngetting help for cloud"
# hlp = command_options_for("cloud", [])
# puts hlp

# puts "\ngetting help for cloud auth"
# hlp = command_options_for("cloud", ["auth"])
# puts hlp

# puts "\ngetting help for cloud auth login"
# hlp = command_options_for("cloud", ["auth", "login"])
# puts hlp
