module YumEpel
  module Cookbook
    module Helpers
      def epel_8_repos
        repos = %w(
          epel
          epel-debuginfo
          epel-modular
          epel-modular-debuginfo
          epel-modular-source
          epel-source
          epel-testing
          epel-testing-debuginfo
          epel-testing-modular
          epel-testing-modular-debuginfo
          epel-testing-modular-source
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
    end
  end
end
# Needed to used in attributes/
Chef::Node.include ::YumEpel::Cookbook::Helpers
