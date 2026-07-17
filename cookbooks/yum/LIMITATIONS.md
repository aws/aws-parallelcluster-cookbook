# Limitations

This cookbook manages Yum/DNF configuration and DNF modules. It does not provide
vendor repositories directly; platform support is constrained by Chef Infra,
available container images, and the operating system's native Yum or DNF
implementation.

## Supported Platforms

The full migration keeps the test matrix on current Enterprise Linux platforms
where Yum/DNF behavior can be verified with Dokken:

* AlmaLinux 8, 9, and 10
* Amazon Linux 2023
* CentOS Stream 9 and 10
* Oracle Linux 8 and 9

EOL platforms such as CentOS 7, CentOS Stream 8, and Oracle Linux 7 were removed
from active testing. Debian, Ubuntu, and openSUSE are not useful targets for this
cookbook because they do not exercise Yum/DNF behavior.

## Package Constraints

The `yum_globalconfig` resource writes `/etc/yum.conf` style configuration. The
`dnf_module` resource shells out to `dnf module` commands during convergence and
therefore requires a platform with DNF module support.

Amazon Linux 2023 is supported by AWS through June 30, 2029. Current Enterprise
Linux lifecycle data was checked against vendor lifecycle references during the
full migration.
