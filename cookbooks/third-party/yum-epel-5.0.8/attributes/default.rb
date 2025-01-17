default['yum-epel']['repos'] =
  value_for_platform(
    %w(almalinux redhat centos oracle rocky) => {
      '>= 8.0' => epel_repos,
      '~> 7.0' =>
        %w(
          epel
          epel-debuginfo
          epel-source
          epel-testing
          epel-testing-debuginfo
          epel-testing-source
        ),
    },
    'amazon' => {
      'default' =>
        %w(
          epel
          epel-debuginfo
          epel-source
          epel-testing
          epel-testing-debuginfo
          epel-testing-source
        ),
      },
    # No-op on non-yum systems
    'default' => []
  )
