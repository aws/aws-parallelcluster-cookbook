require 'spec_helper'

describe 'aws-parallelcluster-platform::cron' do
  cached(:chef_run) do
    ChefSpec::Runner.new.converge(described_recipe)
  end

  it 'creates directories' do
    is_expected.to create_directory('/etc/cron.daily')
    is_expected.to create_directory('/etc/cron.weekly')
  end

  it 'creates /etc/cron.daily/jobs.deny' do
    is_expected.to create_cookbook_file('cron.jobs.deny.daily').with(
      source: 'cron/jobs.deny.daily',
      path: '/etc/cron.daily/jobs.deny',
      owner: 'root',
      group: 'root',
      mode: '0644'
    )
  end

  it 'creates /etc/cron.weekly/jobs.deny' do
    is_expected.to create_cookbook_file('cron.jobs.deny.weekly').with(
      source: 'cron/jobs.deny.weekly',
      path: '/etc/cron.weekly/jobs.deny',
      owner: 'root',
      group: 'root',
      mode: '0644'
    )
  end
end
