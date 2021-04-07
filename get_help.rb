require "vagrant"

def command_help_for(name, subcommand)
  plugin = Vagrant::Plugin::V2::Plugin.manager.commands[name.to_sym].to_a.first
  if !plugin
    raise "Failed to locate command plugin for: #{name}"
  end
  # Create a new anonymous class based on the command class
  # so we can modify the setup behavior
  klass = Class.new(plugin.call)

  # Update the option parsing to store the provided options, and then return
  # a nil value. The nil return will force the command to call help and not
  # actually execute anything.
  klass.class_eval do
    def parse_options(opts)
      Thread.current.thread_variable_set(:command_options, opts)
      nil
    end
  end

  Vagrant::UI::Silent.class_eval do
    def info(message, *opts)
      Thread.current.thread_variable_set(:command_info, message)
      nil
    end
  end
  env = Vagrant::Environment.new(ui: Vagrant::UI::Silent.new)
  # Execute the command to populate our options
  cmd_plg = klass.new(subcommand, env)

  begin
    cmd_plg.execute
  rescue Vagrant::Errors::CLIInvalidUsage
    # This is expected since no args are being provided
  end

  options = Thread.current.thread_variable_get(:command_options)
  msg = Thread.current.thread_variable_get(:command_info)

  # require "pry-byebug"; binding.pry
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
hlp = command_help_for("status", [])
puts hlp

puts "\ngetting help for box"
hlp = command_help_for("box", [])
puts hlp

# puts "\ngetting help for box add"
# hlp = command_help_for("box", ["add"])
# puts hlp
