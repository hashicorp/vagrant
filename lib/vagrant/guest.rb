require "log4r"

module Vagrant
  # This class handles guest-OS specific interactions with a machine.
  # It is primarily responsible for detecting the proper guest OS
  # implementation and then delegating capabilities.
  #
  # Vagrant has many tasks which require specific guest OS knowledge.
  # These are implemented using a guest/capability system. Various plugins
  # register as "guests" which determine the underlying OS of the system.
  # Then, "guest capabilities" register themselves for a specific OS (one
  # or more), and these capabilities are called.
  #
  # Example capabilities might be "mount_virtualbox_shared_folder" or
  # "configure_networks".
  #
  # This system allows for maximum flexibility and pluginability for doing
  # guest OS specific operations.
  class Guest
    attr_reader :chain

    def initialize(machine, guests)
      @logger  = Log4r::Logger.new("vagrant::guest")
      @chain   = []
      @guests  = guests
      @machine = machine
    end

    # This will detect the proper guest OS for the machine and set up
    # the class to actually execute capabilities.
    def detect!
      @logger.info("Detect guest for machine: #{@machine}")

      # Get the mapping of guests with the most parents. We start searching
      # with the guests with the most parents first.
      parent_count = {}
      @guests.each do |name, parts|
        parent_count[name] = 0

        parent = parts[1]
        while parent
          parent_count[name] += 1
          parent = @guests[parent]
          parent = parent[1] if parent
        end
      end

      # Now swap around the mapping so that it is a mapping of
      # count to the actual list of guest names
      parent_count_to_guests = {}
      parent_count.each do |name, count|
        parent_count_to_guests[count] ||= []
        parent_count_to_guests[count] << name
      end

      catch(:guest_os) do
        sorted_counts = parent_count_to_guests.keys.sort.reverse
        sorted_counts.each do |count|
          parent_count_to_guests[count].each do |name|
            @logger.debug("Trying: #{name}")
            guest_info = @guests[name]
            guest      = guest_info[0].new

            if guest.detect?(@machine)
              @logger.info("Detected: #{name}!")
              @chain << guest

              # Build the proper chain of parents if there are any.
              # This allows us to do "inheritence" of capabilities later
              if guest_info[1]
                parent_info = @guests[guest_info[1]]
                while parent_info
                  @chain << parent_info[0].new
                  parent_info = @guests[parent_info[1]]
                end
              end

              @logger.info("Full guest chain: #{@chain.inspect}")

              # Exit the search
              throw :guest_os
            end
          end
        end
      end

      # We shouldn't reach this point. Ideally we would detect
      # all operating systems.
      raise Errors::GuestNotDetected if @chain.empty?
    end

    # This returns whether the guest is ready to work. If this returns
    # `false`, then {#detect!} should be called in order to detect the
    # guest OS.
    #
    # @return [Boolean]
    def ready?
      !@chain.empty?
    end
  end
end
