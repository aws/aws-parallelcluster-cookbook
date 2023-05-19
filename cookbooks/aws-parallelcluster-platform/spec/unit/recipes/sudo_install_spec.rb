require 'spec_helper'

describe 'aws-parallelcluster-platform::sudo_install' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end

      it 'installs sudo package' do
        is_expected.to install_package('sudo')
      end

      it 'creates the template with the correct attributes' do
        is_expected.to create_template('/etc/sudoers.d/99-parallelcluster-secure-path').with(
          owner: 'root',
          group: 'root',
          mode:  '0600'
        )
      end

      it 'has the correct content' do
        is_expected.to render_file('/etc/sudoers.d/99-parallelcluster-secure-path')
          .with_content("Defaults secure_path = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin")
      end
    end
  end
end
