require 'google/rpc/error_details_pb'

module VagrantPlugins
  module CommandServe
    module Util
      # Adds exception logging to all public instance methods
      module ExceptionTransformer
        prepend Util::HasMapper

        def self.included(klass)
          # Get all the public instance methods. Need to search ancestors as well
          # for modules like the Guest service which includes the CapabilityPlatform
          # module
          klass_public_instance_methods = klass.public_instance_methods
          # Remove all generic instance methods from the list of ones to modify
          logged_methods = klass_public_instance_methods - Object.public_instance_methods
          logged_methods.each do |m_name|
            klass.define_method(m_name) do |*args, **opts, &block|
              begin
                super(*args, **opts, &block)
              rescue => err
                if err.is_a?(GRPC::BadStatus)
                  raise err
                end
                localized_msg_details_any = Google::Protobuf::Any.new
                localized_msg_details_any.pack(
                  Google::Rpc::LocalizedMessage.new(
                    locale: "en-US", message: err.message
                  )
                )
                proto = Google::Rpc::Status.new(
                  code: GRPC::Core::StatusCodes::UNKNOWN, 
                  message: "#{err.message}\n#{err.backtrace.join("\n")}",
                  details: [localized_msg_details_any]
                )
                encoded_proto = Google::Rpc::Status.encode(proto)
                grpc_status_details_bin_trailer = 'grpc-status-details-bin'
                grpc_error = GRPC::BadStatus.new(
                  GRPC::Core::StatusCodes::UNKNOWN,
                  err.message,
                  {grpc_status_details_bin_trailer => encoded_proto},
                )
                raise grpc_error
              end
            end
          end
        end
      end
    end
  end
end
