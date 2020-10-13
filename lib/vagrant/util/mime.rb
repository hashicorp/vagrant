require 'mime/types'
require 'securerandom'

module Vagrant
  module Util
    module Mime
      class Multipart

        attr_accessor :content

        attr_accessor :content_type

        attr_accessor :headers

        attr_accessor :mime_version

        def initialize(content_type="multipart/mixed", mime_version="1.0")
          @content_id = "#{SecureRandom.alphanumeric(24)}@#{SecureRandom.alphanumeric(24)}.local"
          @boundary = "Boundary_#{SecureRandom.alphanumeric(24)}"
          @content_type = MIME::Types[content_type].first
          @content = []
          @mime_version = mime_version 
          @headers = {
            "Content-ID"=> "<#{@content_id}>",
            "Content-Type"=> "#{content_type}; boundary=#{@boundary}",
          }
        end

        def add(entry)
          content << entry
        end

        # Output MimeEntity as a string
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

        attr_reader :content

        attr_reader :content_type

        def initialize(content, content_type)
          if !MIME::Types.include?(content_type)
            MIME::Types.add(MIME::Type.new(content_type))
          end
          @content = content
          @content_type = MIME::Types[content_type].first
          @content_id = "#{SecureRandom.alphanumeric(24)}@#{SecureRandom.alphanumeric(24)}.local"
        end

        def to_s
          output_string = "Content-ID: <#{@content_id}>\n"
          output_string += "Content-Type: #{@content_type}\n\n"
          output_string += content
          output_string
        end
      end
    end
  end
end
