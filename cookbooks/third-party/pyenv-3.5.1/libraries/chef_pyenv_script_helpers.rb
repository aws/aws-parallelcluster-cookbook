require 'chef/mixin/shell_out'

class Chef
  module Pyenv
    module ScriptHelpers
      include Chef::Mixin::ShellOut
      def root_path
        node.run_state['sous-chefs'] ||= {}
        node.run_state['sous-chefs']['pyenv'] ||= {}
        node.run_state['sous-chefs']['pyenv']['root_path'] ||= {}

        if new_resource.user
          node.run_state['sous-chefs']['pyenv']['root_path'][new_resource.user]
        else
          node.run_state['sous-chefs']['pyenv']['root_path']['system']
        end
      end

      def which_pyenv
        "(#{new_resource.user || 'system'})"
      end

      def script_code
        script = []
        script << %(export PYENV_ROOT="#{root_path}")
        script << %(export PATH="${PYENV_ROOT}/bin:$PATH")
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
    end
  end
end
