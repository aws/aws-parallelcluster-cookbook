# Intel Packages
default['cluster']['psxe']['version'] = '2020.4-17'
default['cluster']['psxe']['noarch_packages'] = %w(intel-tbb-common-runtime intel-mkl-common-runtime intel-psxe-common-runtime
                                                   intel-ipp-common-runtime intel-ifort-common-runtime intel-icc-common-runtime
                                                   intel-daal-common-runtime intel-comp-common-runtime)
default['cluster']['psxe']['archful_packages']['i486'] = %w(intel-tbb-runtime intel-tbb-libs-runtime intel-comp-runtime
                                                            intel-daal-runtime intel-icc-runtime intel-ifort-runtime
                                                            intel-ipp-runtime intel-mkl-runtime intel-openmp-runtime)
default['cluster']['psxe']['archful_packages']['x86_64'] = node['cluster']['psxe']['archful_packages']['i486'] + %w(intel-mpi-runtime)

default['cluster']['intelhpc']['dependencies'] = %w(compat-libstdc++-33 nscd nss-pam-ldapd openssl098e
                                                    at avahi-libs cups-client cups-libs dejavu-fonts-common dejavu-sans-fonts ed
                                                    fontconfig fontpackages-filesystem freetype gettext gettext-libs hwdata libcroco
                                                    libICE libgomp libSM libX11 libX11-common libXau
                                                    libXcursor libXdamage libXext libXfixes libXft libXi libXinerama libXmu libXp
                                                    libXrandr libXrender libXt libXtst libXxf86vm libdrm libglvnd libglvnd-glx
                                                    libjpeg-turbo libpciaccess libpipeline libpng libpng12 libunistring libxcb
                                                    libxshmfence m4 mailx man-db mariadb-libs mesa-libGL
                                                    mesa-libGLU mesa-libglapi patch pax perl perl-Carp perl-Data-Dumper perl-Encode
                                                    perl-Exporter perl-File-Path perl-File-Temp perl-Filter perl-Getopt-Long perl-HTTP-Tiny
                                                    perl-PathTools perl-Pod-Escapes perl-Pod-Perldoc perl-Pod-Simple perl-Pod-Usage
                                                    perl-Scalar-List-Utils perl-Socket perl-Storable perl-Text-ParseWords perl-Time-HiRes
                                                    perl-Time-Local perl-constant perl-libs perl-macros perl-parent perl-podlators
                                                    perl-threads perl-threads-shared postfix psmisc redhat-lsb-core redhat-lsb-submod-security
                                                    spax tcl tcsh time)

default['cluster']['intelhpc']['packages'] = %w(intel-hpc-platform-core-intel-runtime-advisory intel-hpc-platform-compat-hpc-advisory
                                                intel-hpc-platform-core intel-hpc-platform-core-advisory intel-hpc-platform-hpc-cluster
                                                intel-hpc-platform-compat-hpc intel-hpc-platform-core-intel-runtime)
default['cluster']['intelhpc']['version'] = '2018.0-7'

default['cluster']['intelpython2']['version'] = '2019.4-088'
default['cluster']['intelpython3']['version'] = '2020.2-902'
