dnf_module 'nodejs:12'

package 'nodejs'

dnf_module 'ruby:2.7' do
  action :install
end

dnf_module 'mysql' do
  action :disable
end

# test cache flush
yum_remi_modular 'default'
dnf_module 'php:remi-8.1'

# this would fail if cache is not reloaded
# would still try to install stock php 7.2
package 'php'
