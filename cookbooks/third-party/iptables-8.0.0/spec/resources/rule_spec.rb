require 'spec_helper'

describe 'iptables_rule' do
  step_into :iptables_rule, :iptables_chain
  platform 'centos'

  context 'Creates a basic chain for table filter' do
    recipe do
      iptables_rule 'basic chain rule' do
        table :filter
        chain :INPUT
        ip_version :ipv4
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

  context 'Creates a basic input rule for the filter chain' do
    recipe do
      iptables_rule 'Allow from loopback interface' do
        table :filter
        chain :INPUT
        ip_version :ipv4
        jump 'ACCEPT'
        in_interface 'lo'
      end
    end

    it 'Creates the chain template' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*filter/)
        .with_content(/:INPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:OUTPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:FORWARD\sACCEPT\s\[0\:0\]/)
        .with_content(/\-A\sINPUT\s\-j\sACCEPT\s\-i\slo\s/)
    end
  end

  context 'Creates rules with extra options under a different table with a custom chain' do
    recipe do
      iptables_chain 'mangle' do
        table :mangle
        chain :DIVERT
        value '- [0:0]'
      end

      iptables_rule 'Divert tcp prerouting' do
        table :mangle
        chain :PREROUTING
        protocol :tcp
        match 'socket'
        ip_version :ipv4
        jump 'DIVERT'
      end

      iptables_rule 'Mark Diverted rules' do
        table :mangle
        chain :DIVERT
        ip_version :ipv4
        jump 'MARK'
        extra_options '--set-xmark 0x1/0xffffffff'
      end

      iptables_rule 'accept divert trafic' do
        table :mangle
        chain :DIVERT
        ip_version :ipv4
        jump 'ACCEPT'
      end
    end

    it 'has the default filter chain' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*filter/)
        .with_content(/:INPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:OUTPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:FORWARD\sACCEPT\s\[0\:0\]/)
    end

    it 'has the default mangle chain' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*mangle/)
        .with_content(/:INPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:FORWARD\sACCEPT\s\[0\:0\]/)
        .with_content(/:OUTPUT\sACCEPT\s\[0\:0\]/)
        .with_content(/:POSTROUTING\sACCEPT\s\[0\:0\]/)
    end

    # This one validates that the rules come under the final item in the
    # table, which is the custom chain, hence the multiline
    it 'has the DIVERT chain under table mangle' do
      is_expected.to render_file('/etc/sysconfig/iptables')
        .with_content(/\*mangle/)
        .with_content(/:DIVERT\s-\s\[0\:0\]\s+\-A/m)
        .with_content(/\-A\sPREROUTING\s\-p\stcp\s\-m\ssocket\s\-j\sDIVERT/)
        .with_content(%r{\-A\sDIVERT\s\-j\sMARK\s\-\-set\-xmark\s0x1/0xffffffff})
        .with_content(/\-A\sDIVERT\s\-j\sACCEPT/m)
    end
  end
end
