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
                # Since we are a generated wrapper method, it's common for this
                # transformer to be hit multiple times in a given callstack.
                # That means we need this check to avoid double-wrapping an
                # error.
                if err.is_a?(GRPC::BadStatus)
                  raise
                end

                # Here we build a gRPC-friendly version of the error so that it
                # can be unpacked on the client side.
                #
                # This is using the error model introduced here:
                # https://grpc.io/docs/guides/error/#richer-error-model
                #
                # And detailed here:
                # https://cloud.google.com/apis/design/errors#error_model
                #
                # IMPORTANT: As mentioned in both those links, gRPC error
                # details are returned in headers, and total headers are
                # limited to 8KB. That means we need to be careful not to go
                # over that limit in our messages here (which is easy to do
                # when big backtraces are involved).
                #
                # If we go over that limit, we'll get opaque "RST_STREAM with
                # error code 2" messages from clients, as discussed here:
                # https://github.com/grpc/grpc-go/issues/4265
                #
                # Therefore, here we truncate both message and backtrace to
                # 1024 characters. The message is used in three places and the
                # backtrace in one, so this should hopfully keep the total
                # headers below the limit in most cases.
                message = ExceptionTransformer.truncate_to(err.message, 1024)
                backtrace = ExceptionTransformer.truncate_to(err.backtrace.join("\n"), 1024)
                localized_msg_details_any = Google::Protobuf::Any.new
                localized_msg_details_any.pack(
                  # This is the message we expect to be unpacked and presented
                  # to the user, as it's sometimes a user-facing error.
                  Google::Rpc::LocalizedMessage.new(
                    locale: "en-US", message: message
                  )
                )
                proto = Google::Rpc::Status.new(
                  code: GRPC::Core::StatusCodes::UNKNOWN,
                  message: "#{message}\n#{backtrace}",
                  details: [localized_msg_details_any]
                )
                encoded_proto = Google::Rpc::Status.encode(proto)
                grpc_status_details_bin_trailer = 'grpc-status-details-bin'
                grpc_error = GRPC::BadStatus.new(
                  GRPC::Core::StatusCodes::UNKNOWN,
                  message,
                  {grpc_status_details_bin_trailer => encoded_proto},
                )
                raise grpc_error
              end
            end
          end
        end

        # Truncates a string to a given length if necessary, appending an
        # ellipsis if it does
        def self.truncate_to(str, len)
          if str.length <= len
            str
          else
            str.gsub(/^(.{#{len-3},}?).*$/m, "\1...")
          end
        end
      end
    end
  end
end
