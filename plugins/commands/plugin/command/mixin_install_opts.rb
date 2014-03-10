module VagrantPlugins
  module CommandPlugin
    module Command
      module MixinInstallOpts
        def build_install_opts(o, options)
          o.on("--entry-point NAME", String,
               "The name of the entry point file for loading the plugin.") do |entry_point|
            options[:entry_point] = entry_point
          end

          # @deprecated
          o.on("--plugin-prerelease",
               "Allow prerelease versions of this plugin.") do |plugin_prerelease|
            puts "--plugin-prelease is deprecated and will be removed in the next"
            puts "version of Vagrant. It has no effect now. Use the '--plugin-version'"
            puts "flag to get a specific pre-release version."
            puts
          end

          o.on("--plugin-source PLUGIN_SOURCE", String,
               "Add a RubyGems repository source") do |plugin_source|
            options[:plugin_sources] ||= []
            options[:plugin_sources] << plugin_source
          end

          o.on("--plugin-version PLUGIN_VERSION", String,
               "Install a specific version of the plugin") do |plugin_version|
            options[:plugin_version] = plugin_version
          end

          o.on("--plugin-git GIT_REPOSITORY", String,
               "Install from a git repository") do |plugin_git|
            options[:plugin_git] = plugin_git
          end

          o.on("--plugin-git-ref GIT_REF", String,
               "A git ref (tag/branch/commit) to track") do |plugin_git_ref|
            options[:plugin_git_ref] = plugin_git_ref
          end

          o.on("--plugin-git-tag GIT_TAG", String,
               "A git tag to track") do |plugin_git_tag|
            options[:plugin_git_tag] = plugin_git_tag
          end

          o.on("--plugin-git-branch GIT_BRANCH", String,
               "A git branch to track") do |plugin_git_branch|
            options[:plugin_git_branch] = plugin_git_branch
          end
        end
      end
    end
  end
end
