require 'spec_helper'

class ConvergeAlinuxExtrasTopic
  def self.install(runner:, topic:)
    runner.converge_dsl('aws-parallelcluster-shared') do
      alinux_extras_topic 'install' do
        topic topic
        action :install
      end
    end
  end
end

describe 'alinux_extras_topic:install' do
  cached(:topic) { 'topic_to_install' }
  context 'when not yet installed' do
    cached(:chef_run) do
      stub_command("amazon-linux-extras | grep #{topic} | grep enabled").and_return(false)
      runner = ChefSpec::Runner.new(
        platform: 'amazon', version: 2,
        step_into: ['alinux_extras_topic']
      )
      ConvergeAlinuxExtrasTopic.install(runner: runner, topic: topic)
    end

    it 'installs alinux_extras_topic' do
      is_expected.to install_alinux_extras_topic('install')
    end

    it 'installs the topic' do
      is_expected.to run_execute("amazon-linux-extras install -y #{topic}").with_user('root')
    end
  end

  context 'when already installed' do
    cached(:chef_run) do
      stub_command("amazon-linux-extras | grep #{topic} | grep enabled").and_return(true)
      runner = ChefSpec::Runner.new(
        platform: 'amazon', version: 2,
        step_into: ['alinux_extras_topic']
      )
      ConvergeAlinuxExtrasTopic.install(runner: runner, topic: topic)
    end

    it 'installs alinux_extras_topic' do
      is_expected.to install_alinux_extras_topic('install')
    end

    it 'does not install the topic' do
      is_expected.not_to run_execute("amazon-linux-extras install -y #{topic}")
    end
  end
end
