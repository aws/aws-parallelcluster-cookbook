require 'spec_helper'

describe 'iptables_chain' do
  step_into :iptables_chain
  platform 'centos'

  context 'Creates a basic chain for table filter' do
    recipe do
      iptables_chain 'filter' do
        table :filter
      end
    end

    it 'Creates the chain template' do
      # stub_command('/usr/sbin/apache2ctl -t').and_return('foo')
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*filter/)
        .with_content(/:INPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:OUTPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:FORWARD\sACCEPT\s\[0\:0\]/)
    end
  end

  context 'Creates a custom chain with default value for table filter' do
    recipe do
      iptables_chain 'filter' do
        table :filter
        chain :FOO
      end
    end

    it 'Creates the chain template' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*filter/)
        .with_content(/:INPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:OUTPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:FORWARD\sACCEPT\s\[0\:0\]/)
        .with_content(/:FOO\sACCEPT\s\[0\:0\]/)
    end
  end

  context 'Creates a custom chain with custom value for table filter' do
    recipe do
      iptables_chain 'filter' do
        table :filter
        chain :FOO
        value 'BAR [1:2]'
      end
    end

    it 'Creates the chain template' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*filter/)
        .with_content(/:INPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:OUTPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:FORWARD\sACCEPT\s\[0\:0\]/)
        .with_content(/:FOO\sBAR\s\[1\:2\]/)
    end
  end

  context 'When creating a custom table filter is also created' do
    recipe do
      iptables_chain 'nat' do
        table :nat
      end
    end

    it 'Creates the chain template' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*filter/)
        .with_content(/\*nat/)
    end
  end

  context 'When setting a default chain to another value' do
    recipe do
      iptables_chain 'filter chain input should drop by default' do
        table :filter
        chain :INPUT
        value 'DROP [0:0]'
      end
    end

    it 'Creates the chain template with the different value' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*filter/)
        .with_content(/:INPUT\sDROP\s\[0\:0\]/)
        .with_content(/:OUTPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:FORWARD\sACCEPT\s\[0\:0\]/)
    end
  end

  context 'Creates a custom chain with custom value for multiple tables' do
    recipe do
      iptables_chain 'mangle' do
        table :mangle
        chain :DIVERT
        value '- [0:0]'
      end
      iptables_chain 'filter input should drop' do
        table :filter
        chain :INPUT
        value 'DROP [0:0]'
      end
    end

    it 'Creates the mangle table correctly' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*mangle\s+\:PREROUTING\sACCEPT\s\[\d+\:\d+\]\s+\:INPUT\sACCEPT\s\[\d+\:\d+\]\s+\:FORWARD\sACCEPT\s\[\d+\:\d+\]\s+\:OUTPUT\sACCEPT\s\[\d+\:\d+\]\s+\:POSTROUTING\sACCEPT\s\[\d+\:\d+\]\s+\:DIVERT\s-\s\[\d+\:\d+\]\s+COMMIT/m)
    end
    it 'Creates the filter table correctly' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*filter\s+\:INPUT\sDROP\s\[\d+\:\d+\]\s+\:FORWARD\sACCEPT\s\[\d+\:\d+\]\s+\:OUTPUT\sACCEPT\s\[\d+\:\d+\]\s+COMMIT/m)
    end
  end
end
