module DPL
  class Provider
    class BluemixCloudFoundry < Provider

      # NOTE: Much of this class is duplicated from CloudFoundry.
      # This is by design. By duplicating a manageable amount of
      # code here, we prevent this provider and its gem `dpl-bluemix_cloud_foundry`
      # from having a dependency on `dpl-cloudfoundry`.
      # Having less dependency is desirable when we install this gem
      # from source.

      REGIONS = Hash.new {"api.ng.bluemix.net"}.update(
        "eu-gb" => "api.eu-gb.bluemix.net",
        "eu-de" => "api.eu-de.bluemix.net",
        "au-syd" => "api.au-syd.bluemix.net"
      )

      def initial_go_tools_install
        context.shell 'test $(uname) = "Linux" && rel="linux64-binary" || rel="macosx64"; wget "https://cli.run.pivotal.io/stable?release=${rel}&source=github" -qO cf.tgz && tar -zxvf cf.tgz && rm cf.tgz'
      end

      def check_auth
        set_api
        initial_go_tools_install
        context.shell "./cf api #{option(:api)} #{'--skip-ssl-validation' if options[:skip_ssl_validation]}"
        context.shell "./cf login -u #{option(:username)} -p #{option(:password)} -o #{option(:organization)} -s #{option(:space)}"
        install_plugins if options[:plugins]
      end

      def check_app
        if options[:manifest]
          error 'Application must have a manifest.yml for unattended deployment' unless File.exists? options[:manifest]
        end
      end

      def needs_key?
        false
      end

      def push_app
        command = "./cf #{shell_command} #{options[:app]}#{manifest}"
        log "Command: #{command}"
        error 'Failed to push app' unless context.shell(command)

      ensure
        context.shell "./cf logout"
      end

      def cleanup
      end

      def uncleanup
      end

      def app_name
        options[:app_name].nil? ? "" : " '#{options[:app_name]}'"
      end

      def manifest
        options[:manifest].nil? ? "" : " -f #{options[:manifest]}"
      end

      def set_api
        region = options[:region] || "ng"
        options[:api] = options[:api] || REGIONS[region]
      end

      def install_plugins
        log 'Install plugins'
        plugins.each do |plugin|
          log " - #{plugin}"
          if plugin_installed?(plugin)
            log '   installed'
          else
            error 'Failed to instal plugin' unless context.shell "./cf install-plugin -f #{plugin}"
          end
        end
      end

      def shell_command
        options[:shell] || 'push'
      end

      def plugin_installed?(plugin)
        context.shell("./cf plugins | grep -q #{plugin}")
      end

      def plugins
        option(:plugins).split(',').map(&:strip)
      end
    end
  end
end
