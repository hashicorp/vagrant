require File.expand_path("../version_5_0", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 6.0.x
      class Version_6_0 < Version_5_0
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_6_0")
        end

        def import(ovf)
          ovf = Vagrant::Util::Platform.windows_path(ovf)

          output = ""
          total = ""
          last  = 0

          # Dry-run the import to get the suggested name and path
          @logger.debug("Doing dry-run import to determine parallel-safe name...")
          output = execute("import", "-n", ovf)
          result = /Suggested VM name "(.+?)"/.match(output)
          if !result
            raise Vagrant::Errors::VirtualBoxNoName, output: output
          end
          suggested_name = result[1].to_s

          # Append millisecond plus a random to the path in case we're
          # importing the same box elsewhere.
          specified_name = "#{suggested_name}_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"
          @logger.debug("-- Parallel safe name: #{specified_name}")

          # Build the specified name param list
          name_params = [
            "--vsys", "0",
            "--vmname", specified_name,
          ]

          # Target path for disks is no longer a full path. Extract the path for the
          # settings file to determine the base directory which we can then use to
          # build the disk paths
          result = /Suggested VM settings file name "(?<settings_path>.+?)"/.match(output)
          if !result
            @logger.warn("Failed to locate base path for disks. Using current working directory.")
            base_path = "."
          else
            base_path = result[:settings_path]
            if Vagrant::Util::Platform.windows? || Vagrant::Util::Platform.wsl?
              base_path.gsub!('\\', '/')
            end
            base_path = File.dirname(base_path)
          end

          @logger.info("Base path for disk import: #{base_path}")

          # Extract the disks list and build the disk target params
          disk_params = []
          disks = output.scan(/(\d+): Hard disk image: source image=.+, target path=(.+),/)
          disks.each do |unit_num, path|
            path = File.join(base_path, File.basename(path))
            disk_params << "--vsys"
            disk_params << "0"
            disk_params << "--unit"
            disk_params << unit_num
            disk_params << "--disk"
            disk_params << path.reverse.sub("/#{suggested_name}/".reverse, "/#{specified_name}/".reverse).reverse # Replace only last occurrence
          end

          execute("import", ovf , *name_params, *disk_params, retryable: true) do |type, data|
            if type == :stdout
              # Keep track of the stdout so that we can get the VM name
              output << data
            elsif type == :stderr
              # Append the data so we can see the full view
              total << data.gsub("\r", "")

              # Break up the lines. We can't get the progress until we see an "OK"
              lines = total.split("\n")
              if lines.include?("OK.")
                # The progress of the import will be in the last line. Do a greedy
                # regular expression to find what we're looking for.
                match = /.+(\d{2})%/.match(lines.last)
                if match
                  current = match[1].to_i
                  if current > last
                    last = current
                    yield current if block_given?
                  end
                end
              end
            end
          end

          return get_machine_id specified_name
        end

      end
    end
  end
end
