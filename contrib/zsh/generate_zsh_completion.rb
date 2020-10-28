require 'open3'

HEAD = """#compdef _vagrant vagrant

# ZSH completion for Vagrant
#
# To use this completion add this to ~/.zshrc
# fpath=(/path/to/this/dir $fpath)
# compinit
#
# For development reload the function after making changes
# unfunction _vagrant && autoload -U _vagrant 
"""

BOX_LIST_FUNCTION = """
__box_list ()
{
    _wanted application expl 'command' compadd $(command vagrant box list | awk '{print $1}' )
}
"""

PLUGIN_LIST_FUNCTION = """
__plugin_list ()
{
    _wanted application expl 'command' compadd $(command vagrant plugin list | awk '{print $1}')
}
"""

ADD_FEATURE_FLAGS = ["remove", "repackage", "update", "repair", "uninstall"]
VAGRANT_COMMAND = "vagrant"  

FLAG_REGEX = /--(\S)*/
CMDS_REGEX = /^(\s){1,}(\w)(\S)*/

def make_string_script_safe(s)
  s.gsub("[","(").gsub("]",")").gsub("-","_").gsub("'", "")
end

def remove_square_brakets(s)
  s.gsub("[","(").gsub("]",")")
end

def format_flags(group_name, flags)
  group_name = make_string_script_safe(group_name)
  opts_str = "local -a #{group_name} && #{group_name}=(\n"
  flags.each do |flag, desc|
    opts_str = opts_str + "    '#{remove_square_brakets(flag)}=[#{make_string_script_safe(desc)}]'\n"
  end
  opts_str + ")"
end

def format_subcommand(group_name, cmds)
  opts_str = "local -a #{group_name} && #{group_name}=(\n"
  cmds.each do |cmd, desc|
    opts_str = opts_str + "    '#{cmd}:#{desc}'\n"
  end
  opts_str + ")"
end

def format_case(group_name, cmds, cmd_list, feature_string)
  case_str = """case $state in 
  (command)
    _describe -t commands 'command' #{group_name}
    return
  ;;

  (options)
    case $line[1] in
"""

  cmds.each do |cmd, desc|
    if cmd_list.include?(cmd)
      case_append = """  #{cmd})
    _arguments -s -S : $#{make_string_script_safe(cmd)}_arguments #{feature_string if ADD_FEATURE_FLAGS.include?(cmd)} ;;
"""
    else
      case_append = """  #{cmd})
    __vagrant-#{cmd} ;;
"""
    end
    case_str = case_str + case_append
  end

  case_str = case_str + """esac
  ;;
esac
"""
end

def extract_flags(top_level_commands)
  flags = top_level_commands.map { |c| [c.match(FLAG_REGEX)[0], c.split("  ")[-1].strip] if c.strip.start_with?("--") }.compact
end

def extract_subcommand(top_level_commands)
  cmds = top_level_commands.map { |c| [c.match(CMDS_REGEX)[0].strip, c.split("  ")[-1].strip] if c.match(CMDS_REGEX) }.compact
end

def get_top_level_commands(root_command, cmd_list)
  stdout, stderr, status = Open3.capture3("vagrant #{root_command} -h")
  top_level_commands = stdout.split("\n")
  
  root_subcommand = extract_subcommand(top_level_commands)
  commands = format_subcommand("sub_commands", root_subcommand)
  if root_command == "box"
    feature_string = "':feature:__box_list'"
  elsif root_command == "plugin"
    feature_string = "':feature:__plugin_list'"
  else
    feature_string = ""
  end
  case_string = format_case("sub_commands", root_subcommand, cmd_list, feature_string)

  flags_def = ""
  root_subcommand.each do |cmd, desc|
    next if !cmd_list.include?(cmd)
    stdout, stderr, status = Open3.capture3("vagrant #{root_command} #{cmd} -h")
    cmd_help = stdout.split("\n")
    flags_def = flags_def + format_flags("#{cmd}_arguments", extract_flags(cmd_help)) + "\n\n"
  end

  return commands, flags_def, case_string
end

def format_script(root_command, subcommands, funciton_name)
  top_level_commands, top_level_args, state_case = get_top_level_commands(root_command, subcommands)
  
  script = """
function #{funciton_name} () {

  #{top_level_commands}

  #{top_level_args}

  _arguments -C ':command:->command' '*::options:->options'

#{state_case}
}
"""
end

def generate_script
  subcommand_list = {
    "" => ["cloud", "destroy", "global-status", "halt", "help", "login", "init", "package", "port", "powershell", "provision", "push", "rdp", "reload", "resume", "ssh", "ssh-config", "status", "suspend", "up", "upload", "validate", "version", "winrm", "winrm-config"],
    "box" => ["add", "list", "outdated", "prune", "remove", "repackage", "update"],
    "snapshot" => ["delete", "list", "pop", "push", "restore", "save"],
    "plugin" => ["install", "expunge", "license", "list", "repair", "uninstall", "update"],
  }
  
  script = """#{HEAD}
#{BOX_LIST_FUNCTION}
#{PLUGIN_LIST_FUNCTION}
"""

  subcommand_list.each do |cmd, opts|
    if cmd != ""
      function_name = "__vagrant-#{cmd}"
    else
      function_name = "_vagrant"
    end
    script = script + format_script(cmd, opts, function_name)
  end
  script
end

puts generate_script
