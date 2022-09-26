class PyEnv
  module Cookbook
    module ScriptHelpers
      require 'chef/mixin/shell_out'

      include Chef::Mixin::ShellOut
      def root_path
        node.run_state['sous-chefs']['pyenv']['root_path']['prefix']
      end

      def script_code
        script = []
        script << %(export PYENV_ROOT="#{root_path}")
        script << %(export PATH="${PYENV_ROOT}/bin:${PYENV_ROOT}/shims:$PATH")
        script << %{eval "$(pyenv init -)"}
        if new_resource.pyenv_version
          script << %(export PYENV_VERSION="#{new_resource.pyenv_version}")
        end
        script << new_resource.code
        script.join("\n").concat("\n")
      end

      def script_environment
        script_env = { 'PYENV_ROOT' => root_path }
        script_env.merge!(new_resource.environment) if new_resource.environment

        if new_resource.path
          script_env['PATH'] = "#{new_resource.path.join(':')}:#{ENV['PATH']}"
        end

        if new_resource.user
          script_env['USER'] = new_resource.user
          script_env['HOME'] = ::File.expand_path("~#{new_resource.user}")
        end

        script_env
      end

      def pip_command(command)
        pip = if new_resource.virtualenv
                "#{new_resource.virtualenv}/bin/pip"
              else
                'pip'
              end

        shell_out("#{pip} #{command}",
                  environment: {
                    'PATH' => "#{root_path}/shims:#{ENV['PATH']}",
                  },
                  user: new_resource.user)
      end

      def pyenv_prerequisites
        case node['platform_family']
        when 'debian'
          %w(make libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git)
        when 'rhel', 'fedora', 'amazon'
          %w(git zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel findutils)
        when 'suse'
          %w(git git-core zlib-devel bzip2 libbz2-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel)
        when 'mac_os_x'
          %w(git readline xz)
        end
      end
    end
  end
end
