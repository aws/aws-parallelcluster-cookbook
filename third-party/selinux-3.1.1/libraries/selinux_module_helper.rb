module SELinux
  # Represents a given SELinux module where you can execute tasks like reading
  # if it's installed, up-to-date and such.
  class Module
    attr_accessor :installed_modules

    # Constructor loads the installed modules and initialize attributes
    #   +module_name+  SELinux module name
    def initialize(module_name)
      @module_name = module_name
      @installed_modules = list_installed_modules
    end

    # Boolean return. When version informed will check for specific version
    # otherwise only if module name is installed.
    #   +version+  module version string;
    def installed?(version = nil)
      return false unless @installed_modules.key?(@module_name)
      return @installed_modules[@module_name] == version if version
      true
    end

    # Invokes command to list installed modules and using regexp converts this
    # to a Hash as return.
    def list_installed_modules
      installed_modules = {}
      exec_semodule_cmd.each_line do |line|
        line.chomp
        if (match = line.match(/^(\w+.*?)\s+((\d+\.)?(\d+\.)?(\*|\d+))/))
          module_name, version = match.captures
          installed_modules[module_name] = version
        end
      end
      installed_modules
    end

    # Mixlib::ShellOut wrapper to execute `/sbin/semodule` to check for command
    # execution errors and return stdout.
    def exec_semodule_cmd
      cmd = Mixlib::ShellOut.new('/usr/sbin/semodule --list-modules', returns: [0])
      cmd.run_command
      unless cmd.stderr.empty?
        Chef::Log.fatal("Error on `#{cmd}`: #{cmd.stderr}")
      end
      cmd.stdout
    end
  end
end
