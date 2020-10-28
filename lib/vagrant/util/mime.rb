require 'mime/types'
require 'securerandom'

module Vagrant
  module Util
    module Mime
      class Multipart

        # @return [Array<String>] collection of content part of the multipart mime
        attr_accessor :content

        # @return [String] type of the content
        attr_accessor :content_type

        # @return [Hash] headers for the mime
        attr_accessor :headers

        # @param [String] (optional) mime content type
        # @param [String] (optional) mime version
        def initialize(content_type="multipart/mixed")
          @content_id = "#{Time.now.to_i}@#{SecureRandom.alphanumeric(24)}.local"
          @boundary = "Boundary_#{SecureRandom.alphanumeric(24)}"
          @content_type = MIME::Types[content_type].first
          @content = []
          @headers = {
            "Content-ID"=> "<#{@content_id}>",
            "Content-Type"=> "#{content_type}; boundary=#{@boundary}",
          }
        end

        # Add an entry to the multipart mime
        #
        # @param entry to add
        def add(entry)
          content << entry
        end

        # Output MimeEntity as a string
        #
        # @return [String] mime data
        def to_s
          output_string = ""
          headers.each do |k, v|
            output_string += "#{k}: #{v}\n"
          end
          output_string += "\n--#{@boundary}\n"
          @content.each do |entry|
            output_string += entry.to_s
            output_string += "\n--#{@boundary}\n"
          end
          output_string
        end
      end

      class Entity

        # @return [String] entity content 
        attr_reader :content

        # @return [String] type of the entity content
        attr_reader :content_type

        # @return [String] content disposition
        attr_accessor :disposition

        # @param [String] entity content
        # @param [String] type of the entity content
        def initialize(content, content_type)
          if !MIME::Types.include?(content_type)
            MIME::Types.add(MIME::Type.new(content_type))
          end
          @content = content
          @content_type = MIME::Types[content_type].first
          @content_id = "#{Time.now.to_i}@#{SecureRandom.alphanumeric(24)}.local"
        end

        # Output MimeEntity as a string
        #
        # @return [String] mime data
        def to_s
          output_string = "Content-ID: <#{@content_id}>\n"
          output_string += "Content-Type: #{@content_type}\n"
          if disposition
            output_string += "Content-Disposition: #{@disposition}\n"
          end
          output_string += "\n#{content}"
          output_string
        end
      end
    end
  end
end
