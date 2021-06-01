default['yum-epel']['repos'] =
  value_for_platform(
    %w(redhat centos oracle) => {
      '>= 8.0' =>
        %w(
          epel
          epel-debuginfo
          epel-modular
          epel-modular-debuginfo
          epel-modular-source
          epel-playground
          epel-playground-debuginfo
          epel-playground-source
          epel-source
          epel-testing
          epel-testing-debuginfo
          epel-testing-modular
          epel-testing-modular-debuginfo
          epel-testing-modular-source
          epel-testing-source
        ),
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
