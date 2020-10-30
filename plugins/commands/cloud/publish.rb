require 'optparse'
require "vagrant/util/uploader"

module VagrantPlugins
  module CloudCommand
    module Command
      class Publish < Vagrant.plugin("2", :command)
        include Util

        def execute
          options = {direct_upload: true}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant cloud publish [options] organization/box-name version provider-name [provider-file]"
            o.separator ""
            o.separator "Create and release a new Vagrant Box on Vagrant Cloud"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--box-version VERSION", String, "Version of box to create") do |v|
              options[:box_version] = v
            end
            o.on("--url URL", String, "Remote URL to download this provider (cannot be used with provider-file)") do |u|
              options[:url] = u
            end
            o.on("-d", "--description DESCRIPTION", String, "Full description of box") do |d|
              options[:description] = d
            end
            o.on("--version-description DESCRIPTION", String, "Description of the version to create") do |v|
              options[:version_description] = v
            end
            o.on("-f", "--[no-]force", "Disables confirmation to create or update box") do |f|
              options[:force] = f
            end
            o.on("-p", "--[no-]private", "Makes box private") do |p|
              options[:private] = p
            end
            o.on("-r", "--[no-]release", "Releases box") do |p|
              options[:release] = p
            end
            o.on("-s", "--short-description DESCRIPTION", String, "Short description of the box") do |s|
              options[:short_description] = s
            end
            o.on("-c", "--checksum CHECKSUM_VALUE", String, "Checksum of the box for this provider. --checksum-type option is required.") do |c|
              options[:checksum] = c
            end
            o.on("-C", "--checksum-type TYPE", String, "Type of checksum used (md5, sha1, sha256, sha384, sha512). --checksum option is required.") do |c|
              options[:checksum_type] = c
            end
            o.on("--[no-]direct-upload", "Upload asset directly to backend storage") do |d|
              options[:direct_upload] = d
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          if argv.length < 3 || # missing required arguments
              argv.length > 4 || # too many arguments
              (argv.length < 4 && !options.key?(:url)) || # file argument required if url is not provided
              (argv.length > 3 && options.key?(:url)) # cannot provider url and file argument
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          org, box_name = argv.first.split('/', 2)
          _, version, provider_name, box_file = argv

          if box_file && !File.file?(box_file)
            raise Vagrant::Errors::BoxFileNotExist,
              file: box_file
          end

          @client = client_login(@env)
          params = options.slice(:private, :release, :url, :short_description,
            :description, :version_description, :checksum, :checksum_type)

          # Display output to user describing action to be taken
          display_preamble(org, box_name, version, provider_name, params)

          if !options[:force]
            cont = @env.ui.ask(I18n.t("cloud_command.continue"))
            return 1 if cont.strip.downcase != "y"
          end

          # Load up all the models we'll need to publish the asset
          box = load_box(org, box_name, @client.token)
          box_v = load_box_version(box, version)
          box_p = load_version_provider(box_v, provider_name)

          # Update all the data
          set_box_info(box, params.slice(:private, :short_description, :description))
          set_version_info(box_v, params.slice(:version_description))
          set_provider_info(box_p, params.slice(:checksum, :checksum_type, :url))

          # Save any updated state
          @env.ui.warn(I18n.t("cloud_command.publish.box_save"))
          box.save

          # If we have a box file asset, upload it
          if box_file
            upload_box_file(box_p, box_file, options.slice(:direct_upload))
          end

          # If configured to release the box, release it
          if options[:release] && !box_v.released?
            release_version(box_v)
          end

          # And we're done!
          @env.ui.success(I18n.t("cloud_command.publish.complete", org: org, box_name: box_name))
          format_box_results(box, @env)
          0
        rescue VagrantCloud::Error => err
          @env.ui.error(I18n.t("cloud_command.errors.publish.fail", org: org, box_name: box_name))
          @env.ui.error(err.message)
          1
        end

        # Upload the file for the given box provider
        #
        # @param [VagrantCloud::Box::Provider] provider Vagrant Cloud box version provider
        # @param [String] box_file Path to local asset for upload
        # @param [Hash] options
        # @option options [Boolean] :direct_upload Upload directly to backend storage
        # @return [nil]
        def upload_box_file(provider, box_file, options={})
          box_file = File.absolute_path(box_file)
          @env.ui.info(I18n.t("cloud_command.publish.upload_provider", file: box_file))
          provider.upload(direct: options[:direct_upload]) do |upload_url|
            Vagrant::Util::Uploader.new(upload_url, box_file, ui: @env.ui, method: :put).upload!
          end
          nil
        end

        # Release the box version
        #
        # @param [VagrantCloud::Box::Version] version Vagrant Cloud box version
        # @return [nil]
        def release_version(version)
          @env.ui.info(I18n.t("cloud_command.publish.release"))
          version.release
          nil
        end

        # Set any box related attributes that were provided
        #
        # @param [VagrantCloud::Box] box Vagrant Cloud box
        # @param [Hash] options
        # @option options [Boolean] :private Box access is private
        # @option options [String] :short_description Short description of box
        # @option options [String] :description Full description of box
        # @return [VagrantCloud::Box]
        def set_box_info(box, options={})
          box.private = options[:private] if options.key?(:private)
          box.short_description = options[:short_description] if options.key?(:short_description)
          box.description = options[:description] if options.key?(:description)
          box
        end

        # Set any version related attributes that were provided
        #
        # @param [VagrantCloud::Box::Version] version Vagrant Cloud box version
        # @param [Hash] options
        # @option options [String] :version_description Description for this version
        # @return [VagrantCloud::Box::Version]
        def set_version_info(version, options={})
          version.description = options[:version_description] if options.key?(:version_description)
          version
        end

        # Set any provider related attributes that were provided
        #
        # @param [VagrantCloud::Box::Provider] provider Vagrant Cloud box version provider
        # @param [Hash] options
        # @option options [String] :url Remote URL for self hosted
        # @option options [String] :checksum_type Type of checksum value provided
        # @option options [String] :checksum Checksum of the box asset
        # @return [VagrantCloud::Box::Provider]
        def set_provider_info(provider, options={})
          provider.url = options[:url] if options.key?(:url)
          provider.checksum_type = options[:checksum_type] if options.key?(:checksum_type)
          provider.checksum = options[:checksum] if options.key?(:checksum)
          provider
        end

        # Load the requested version provider
        #
        # @param [VagrantCloud::Box::Version] version The version of the Vagrant Cloud box
        # @param [String] provider_name Name of the provider
        # @return [VagrantCloud::Box::Provider]
        def load_version_provider(version, provider_name)
          provider = version.providers.detect { |pv| pv.name == provider_name }
          return provider if provider
          version.add_provider(provider_name)
        end

        # Load the requested box version
        #
        # @param [VagrantCloud::Box] box The Vagrant Cloud box
        # @param [String] version Version of the box
        # @return [VagrantCloud::Box::Version]
        def load_box_version(box, version)
          v = box.versions.detect { |v| v.version == version }
          return v if v
          box.add_version(version)
        end

        # Load the requested box
        #
        # @param [String] org Organization name for box
        # @param [String] box_name Name of the box
        # @param [String] access_token User access token
        # @return [VagrantCloud::Box]
        def load_box(org, box_name, access_token)
          account = VagrantCloud::Account.new(
            custom_server: api_server_url,
            access_token: access_token
          )
          box = account.organization(name: org).boxes.detect { |b| b.name == box_name }
          return box if box
          account.organization(name: org).add_box(box_name)
        end

        # Display publishing information to user before starting process
        #
        # @param [String] org Organization name
        # @param [String] box_name Name of the box to publish
        # @param [String] version Version of the box to publish
        # @param [String] provider_name Name of the provider being published
        # @param [Hash] options
        # @option options [Boolean] :private Box is private
        # @option options [Boolean] :release Box should be released
        # @option options [String] :url Remote URL for self-hosted boxes
        # @option options [String] :description Description of the box
        # @option options [String] :short_description Short description of the box
        # @option options [String] :version_description Description of the box version
        # @return [nil]
        def display_preamble(org, box_name, version, provider_name, options={})
          @env.ui.warn(I18n.t("cloud_command.publish.confirm.warn"))
          @env.ui.info(I18n.t("cloud_command.publish.confirm.box", org: org,
            box_name: box_name, version: version, provider_name: provider_name))
          @env.ui.info(I18n.t("cloud_command.publish.confirm.private")) if options[:private]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.release")) if options[:release]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.box_url",
            url: options[:url])) if options[:url]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.box_description",
            description: options[:description])) if options[:description]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.box_short_desc",
            short_description: options[:short_description])) if options[:short_description]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.version_desc",
            version_description: options[:version_description])) if options[:version_description]
          nil
        end
      end
    end
  end
end
