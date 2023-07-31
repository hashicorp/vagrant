# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

shared_context "synced folder actions" do
  # This creates a synced folder implementation.
  def impl(usable, name)
    Class.new(Vagrant.plugin("2", :synced_folder)) do
      define_method(:name) do
        name
      end

      define_method(:usable?) do |machine, raise_error=false|
        raise "#{name}: usable" if raise_error && !usable
        usable
      end

      define_method(:_initialize) do |machine, type|
        true
      end
    end
  end
end
