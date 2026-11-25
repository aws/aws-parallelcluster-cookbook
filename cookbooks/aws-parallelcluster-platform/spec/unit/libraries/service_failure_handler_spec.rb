# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../libraries/service_failure_handler'

describe ErrorHandlers::ServiceFailureHandler do
  let(:handler) { described_class.new }
  let(:action_collection) { double('action_collection') }

  def record(resource_name, **attributes)
    double('action_record', new_resource: double("#{resource_name}_resource", resource_name: resource_name, **attributes))
  end

  def shell_result(stdout)
    double('shell_out_result', stdout: stdout, stderr: '')
  end

  before do
    allow(handler).to receive(:action_collection).and_return(action_collection)
    allow(Chef::Log).to receive(:error)
    allow(Chef::Log).to receive(:warn)
  end

  describe '#unit_of' do
    it 'returns the service of a service resource' do
      expect(handler.unit_of(record(:service, service_name: 'gdrcopy').new_resource)).to eq('gdrcopy')
    end

    it 'returns the unit of a systemd_unit resource' do
      expect(handler.unit_of(record(:systemd_unit, unit_name: 'efa.service').new_resource)).to eq('efa.service')
    end

    {
      'systemctl is-active --quiet slurmd.service' => 'slurmd.service',
      'systemctl is-active slurmctld' => 'slurmctld',
      '/usr/bin/systemctl is-active -q munge && echo ok' => 'munge',
      'systemctl restart slurmd' => nil,
      'scontrol reconfigure' => nil,
    }.each do |command, unit|
      it "returns #{unit.inspect} for an execute running '#{command}'" do
        expect(handler.unit_of(record(:execute, command: command).new_resource)).to eq(unit)
      end
    end

    it 'returns nil for any other resource' do
      expect(handler.unit_of(record(:template).new_resource)).to be_nil
    end
  end

  describe '#failed_units' do
    it 'returns the units of the failed service resources and checks, once each' do
      allow(action_collection).to receive(:filtered_collection).with(
        up_to_date: false, skipped: false, updated: false, failed: true, unprocessed: false
      ).and_return([
                     record(:gdrcopy),
                     record(:service, service_name: 'gdrcopy'),
                     record(:execute, command: 'systemctl is-active --quiet slurmd.service'),
                     record(:execute, command: 'systemctl is-active --quiet slurmd.service'),
                   ])

      expect(handler.failed_units).to eq(%w(gdrcopy slurmd.service))
    end
  end

  describe '#report' do
    it 'logs the status and the journal of each failed unit' do
      allow(handler).to receive(:failed_units).and_return(['slurmd.service'])
      expect(handler).to receive(:shell_out).with('systemctl', 'status', 'slurmd.service', '--no-pager', '--full', timeout: 30)
                                            .and_return(shell_result('Active: failed'))
      expect(handler).to receive(:shell_out).with('journalctl', '--unit', 'slurmd.service', '--lines', '100', '--no-pager', timeout: 30)
                                            .and_return(shell_result('fatal: Unable to determine this slurmd NodeName'))
      expect(Chef::Log).to receive(:error).with(/Service slurmd.service is not running/)
      expect(Chef::Log).to receive(:error).with(/Output of 'systemctl status slurmd.service --no-pager --full':\nActive: failed/)
      expect(Chef::Log).to receive(:error).with(/Unable to determine this slurmd NodeName/)

      handler.report
    end

    it 'does nothing when no service failed' do
      allow(handler).to receive(:failed_units).and_return([])
      expect(handler).not_to receive(:shell_out)

      handler.report
    end

    it 'keeps logging when a command cannot run' do
      allow(handler).to receive(:failed_units).and_return(['gdrcopy'])
      allow(handler).to receive(:shell_out).and_raise(Mixlib::ShellOut::CommandTimeout.new('timed out'))
      expect(Chef::Log).to receive(:warn).with(/Could not run 'systemctl status gdrcopy --no-pager --full': timed out/)
      expect(Chef::Log).to receive(:warn).with(/Could not run 'journalctl --unit gdrcopy/)

      expect { handler.report }.not_to raise_error
    end

    it 'never raises' do
      allow(handler).to receive(:failed_units).and_raise(StandardError.new('no action collection'))
      expect(Chef::Log).to receive(:warn).with(/Failed with error: no action collection/)

      expect { handler.report }.not_to raise_error
    end
  end
end
