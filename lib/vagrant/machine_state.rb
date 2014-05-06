module Vagrant
  # This represents the state of a given machine. This is a very basic
  # class that simply stores a short and long description of the state
  # of a machine.
  #
  # The state also stores a state "id" which can be used as a unique
  # identifier for a state. This should be a symbol. This allows internal
  # code to compare state such as ":not_created" instead of using
  # string comparison.
  #
  # The short description should be a single word description of the
  # state of the machine such as "running" or "not created".
  #
  # The long description can span multiple lines describing what the
  # state actually means.
  class MachineState
    # This is a special ID that can be set for the state ID that
    # tells Vagrant that the machine is not created. If this is the
    # case, then Vagrant will set the ID to nil which will automatically
    # clean out the machine data directory.
    NOT_CREATED_ID = :not_created

    # Unique ID for this state.
    #
    # @return [Symbol]
    attr_reader :id

    # Short description for this state.
    #
    # @return [String]
    attr_reader :short_description

    # Long description for this state.
    #
    # @return [String]
    attr_reader :long_description

    # Creates a new instance to represent the state of a machine.
    #
    # @param [Symbol] id Unique identifier for this state.
    # @param [String] short Short (preferably one-word) description of
    #   the state.
    # @param [String] long Long description (can span multiple lines)
    #   of the state.
    def initialize(id, short, long)
      @id                = id
      @short_description = short
      @long_description  = long
    end
  end
end
