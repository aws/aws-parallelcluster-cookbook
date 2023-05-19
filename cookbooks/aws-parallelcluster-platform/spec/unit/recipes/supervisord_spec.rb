require 'spec_helper'

describe 'aws-parallelcluster-platform::supervisord' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:cookbook_venv_path) { 'cookbook_virtualenv_test_path' }
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_venv_path)
        runner(platform: platform, version: version).converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates supervisord.conf' do
        is_expected.to create_cookbook_file('supervisord.conf').with(
          source: "supervisord.conf",
          path: "/etc/supervisord.conf",
          owner: "root",
          group: "root",
          mode: "0644"
        )
      end

      it 'creates supervisord.service' do
        is_expected.to create_template('supervisord-service').with(
          source: "supervisord-service.erb",
          path: "/etc/systemd/system/supervisord.service",
          owner: "root",
          group: "root",
          mode: "0644",
          variables: { cookbook_virtualenv_path: cookbook_venv_path }
        )
      end

      it 'has the correct content' do
        is_expected.to render_file('/etc/systemd/system/supervisord.service')
          .with_content(%r{ExecStart=#{cookbook_venv_path}/bin/supervisord -n -c /etc/supervisord.conf})
          .with_content(%r{ExecStop=#{cookbook_venv_path}/bin/supervisorctl \$OPTIONS shutdown})
          .with_content(%r{ExecReload=#{cookbook_venv_path}/bin/supervisorctl -c /etc/supervisord.conf \$OPTIONS reload})
      end
    end
  end
end
