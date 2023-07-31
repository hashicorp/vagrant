# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "fake_ftp"

module FakeFtp
  class File
    def initialize(name = nil, data = nil, type = nil,
      last_modified_time = Time.now)
      @created = Time.now
      @name = name
      @data = data
      @bytes = data_is_bytes(data) ? data : data.bytes.length
      @data = data_is_bytes(data) ? nil : data
      @type = type
      @last_modified_time = last_modified_time.utc
    end

    def data_is_bytes(d)
      d.nil? || d.is_a?(Integer)
    end

    def data=(data)
      @bytes = data_is_bytes(data) ? data : data.bytes.length
      @data = data_is_bytes(data) ? nil : data
    end
  end
end
