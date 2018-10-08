require 'optparse'

require "vagrant/util/safe_puts"

module VagrantPlugins
  module CommandWinRM
    class Command < Vagrant.plugin("2", :command)
      include Vagrant::Util::SafePuts

      def self.synopsis
        "executes commands on a machine via WinRM"
      end

      def execute
        options = {
          command: [],
          shell: :powershell
        }

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant winrm [options] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("-c", "--command COMMAND", "Execute a WinRM command directly") do |c|
            options[:command] << c
          end

          o.on("-e", "--elevated", "Run with elevated credentials") do |e|
            options[:elevated] = true
          end

          o.on("-s", "--shell SHELL", [:powershell, :cmd], "Use specified shell (powershell, cmd)") do |s|
            options[:shell] = s
          end
        end

        argv = parse_options(opts)
        return if !argv

        with_target_vms(argv, single_target: true) do |machine|
          if machine.config.vm.communicator != :winrm
            raise Vagrant::Errors::WinRMInvalidCommunicator
          end

          opts = {
            shell: options[:shell],
            elevated: !!options[:elevated]
          }

          options[:command].each do |cmd|
            begin
              machine.communicate.execute(cmd, opts) do |type, data|
                io = type == :stderr ? $stderr : $stdout
                safe_puts(data, io: io, printer: :print)
              end
            rescue VagrantPlugins::CommunicatorWinRM::Errors::WinRMBadExitStatus
              return 1
            end
          end
        end

        # Success, exit status 0
        0
      end
    end
  end
end
