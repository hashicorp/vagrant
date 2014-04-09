module VagrantTests
  module DummyCommunicator
    class Communicator < Vagrant.plugin("2", :communicator)
      def ready?
        true
      end

      attr_reader :known_commands

      def initialize(machine)
        @known_commands = Hash.new do |hash, key|
          hash[key] = { expected: 0, received: 0, response: nil }
        end
      end

      def expected_commands
        known_commands.select do |command, info|
          info[:expected] > 0
        end
      end

      def received_commands
        known_commands.select do |command, info|
          info[:received] > 0
        end.keys
      end

      def stub_command(command, response)
        known_commands[command][:response] = response
      end

      def expect_command(command)
        known_commands[command][:expected] += 1
      end

      def received_summary
        received_commands.map { |cmd| " - #{cmd}" }.unshift('received:').join("\n")
      end

      def verify_expectations!
        expected_commands.each do |command, info|
          if info[:expected] != info[:received]
            fail([
              "expected to receive '#{command}' #{info[:expected]} times",
              "got #{info[:received]} times instead",
              received_summary
            ].join("\n"))
          end
        end
      end

      def execute(command, opts=nil)
        known = known_commands[command]
        known[:received] += 1
        response = known[:response]
        return unless response

        if block_given?
          [:stdout, :stderr].each do |type|
            Array(response[type]).each do |line|
              yield type, line
            end
          end
        end

        if response[:raise]
          raise response[:raise]
        end

        response[:exit_code]
      end

      def sudo(command, opts=nil, &block)
        execute(command, opts, &block)
      end

      def test(command, opts=nil)
        execute(command, opts) == 0
      end
    end
  end
end

