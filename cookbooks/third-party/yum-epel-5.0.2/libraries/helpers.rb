module YumEpel
  module Cookbook
    module Helpers
      def epel_repos
        repos = %w(
          epel
          epel-debuginfo
          epel-source
          epel-testing
          epel-testing-debuginfo
          epel-testing-source
        )

        repos.concat(
          %w(
            epel-next
            epel-next-debuginfo
            epel-next-source
            epel-next-testing
            epel-next-testing-debuginfo
            epel-next-testing-source
          )
        ) if yum_epel_centos_stream?

        repos
      end

      private

      def yum_epel_centos_stream?
        respond_to?(:centos_stream_platform?) && centos_stream_platform?
      end

      def yum_epel_release
        if platform?('amazon')
          case node['platform_version'].to_i
          when 2023
            9
          when 2
            7
          end
        else
          node['platform_version'].to_i
        end
      end
    end
  end
end
# Needed to used in attributes/
Chef::Node.include ::YumEpel::Cookbook::Helpers
