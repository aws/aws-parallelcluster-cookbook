require 'spec_helper'

class ConvergeInstallPackages
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      install_packages 'setup' do
        action :setup
      end
    end
  end
end

describe 'install_packages default_packages' do
  EXPECTED_PACKAGES = {
    'amazon2' => %w(vim ksh tcsh zsh openssl11-devel ncurses-devel pam-devel net-tools openmotif-devel
                    libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                    httpd boost-devel system-lsb mlocate atlas-devel glibc-static iproute
                    libffi-devel dkms libedit-devel sendmail cmake byacc libglvnd-devel libgcrypt-devel libevent-devel
                    libxml2-devel perl-devel tar gzip bison flex gcc gcc-c++ patch
                    rpm-build rpm-sign system-rpm-config cscope ctags diffstat doxygen elfutils
                    gcc-gfortran git indent intltool patchutils rcs subversion swig systemtap curl
                    jq wget python-pip NetworkManager-config-routing-rules
                    python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
                    coreutils moreutils environment-modules bzip2 dos2unix),
    'amazon2023' => %w(ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools
                       libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf libtool
                       httpd boost-devel mlocate R atlas-devel
                       blas-devel libffi-devel dkms libedit-devel jq
                       libical-devel sendmail libxml2-devel libglvnd-devel
                       libgcrypt-devel libevent-devel glibc-static bind-utils
                       iproute python3 python3-pip libcurl-devel git
                       coreutils environment-modules gcc gcc-c++ bzip2 iptables vim yum-plugin-versionlock dos2unix),
    'redhat' => %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                    libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf libtool
                    httpd boost-devel mlocate R atlas-devel
                    blas-devel libffi-devel dkms libedit-devel jq
                    libical-devel sendmail libxml2-devel libglvnd-devel
                    libgcrypt-devel libevent-devel glibc-static bind-utils
                    iproute NetworkManager-config-routing-rules python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
                    coreutils moreutils curl environment-modules gcc gcc-c++ bzip2 dos2unix),
    'rocky' => %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                   libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf libtool
                   httpd boost-devel mlocate R atlas-devel
                   blas-devel libffi-devel dkms libedit-devel jq
                   libical-devel sendmail libxml2-devel libglvnd-devel
                   libgcrypt-devel libevent-devel glibc-static bind-utils
                   iproute NetworkManager-config-routing-rules python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
                   moreutils curl environment-modules gcc gcc-c++ bzip2 dos2unix coreutils),
    'ubuntu' => %w(vim ksh tcsh zsh libssl-dev ncurses-dev libpam-dev net-tools libhwloc-dev dkms
                     tcl-dev automake autoconf libtool librrd-dev libapr1-dev libconfuse-dev
                     apache2 libboost-dev libdb-dev libncurses5-dev libpam0g-dev libxt-dev
                     libmotif-dev libxmu-dev libxft-dev man-db jq
                     r-base libblas-dev libffi-dev libxml2-dev
                     libgcrypt20-dev libevent-dev iproute2 python3 python3-pip
                     libatlas-base-dev libglvnd-dev iptables libcurl4-openssl-dev
                     coreutils moreutils curl python3-parted environment-modules libdbus-1-dev dos2unix),
  }.freeze

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['install_packages'])
        ConvergeInstallPackages.setup(runner)
      end
      cached(:resource) do
        chef_run.find_resource('install_packages', 'setup')
      end

      it 'returns expected packages' do
        expected_key = %(amazon).include?(platform) ? "#{platform}#{version}" : "#{platform}"
        expect(resource.default_packages).to eq(EXPECTED_PACKAGES[expected_key])
      end

      case "#{platform}#{version}"
      when 'amazon2'
        it 'excludes moreutils for us-iso regions' do
          allow(resource).to receive(:aws_region).and_return('us-iso-WHATEVER')
          expect(resource.default_packages).not_to include('moreutils')
        end
      when 'redhat8'
        it 'excludes multiple packages for us-iso regions' do
          allow(resource).to receive(:aws_region).and_return('us-iso-WHATEVER')
          packages = resource.default_packages
          %w(openmotif-devel hwloc-devel R blas-devel dkms libedit-devel glibc-static
             NetworkManager-config-routing-rules yum-plugin-versionlock moreutils).each do |pkg|
            expect(packages).not_to include(pkg)
          end
        end
      end
    end
  end
end

describe 'install_packages:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:default_packages) { %w(package1 package2) }
      cached(:kernel_release) { 'kernel_release.x86_64' }
      cached(:chef_run) do
        stubs_for_resource('install_packages') do |res|
          allow(res).to receive(:default_packages).and_return(default_packages)
        end
        runner = runner(platform: platform, version: version, step_into: ['install_packages']) do |node|
          node.automatic['kernel']['release'] = kernel_release
        end
        ConvergeInstallPackages.setup(runner)
      end
      cached(:node) { chef_run.node }

      it 'sets up node packages' do
        is_expected.to setup_install_packages('setup')
        is_expected.to install_install_packages('default')
      end

      if %w(amazon centos redhat rocky).include?(platform)
        it 'installs default packages' do
          is_expected.to install_package(default_packages)
            .with(retries: 10)
            .with(retry_delay: 5)
            .with(flush_cache: { before: true })
        end

        if platform == 'amazon' && version == '2'
          it 'installs extra packages' do
            is_expected.to install_alinux_extras_topic('R3.4')
          end
        end

      elsif platform == 'ubuntu'
        it 'installs base packages' do
          is_expected.to install_package(default_packages)
            .with(retries: 10)
            .with(retry_delay: 5)
        end

      else
        pending "Implement for #{platform}"
      end
    end
  end
end
