require 'spec_helper'

describe 'user_ulimit resource' do
  step_into :user_ulimit
  platform 'ubuntu'

  context 'without the filename specified' do
    recipe do
      user_ulimit 'tomcat' do
        filehandle_soft_limit 8192
      end
    end

    it { is_expected.to create_template('/etc/security/limits.d/tomcat_limits.conf') }
  end

  context 'with the filename specified and not ending in .conf' do
    recipe do
      user_ulimit 'tomcat' do
        filename 'foo'
        filehandle_soft_limit 8192
      end
    end

    it { is_expected.to create_template('/etc/security/limits.d/foo.conf') }
  end

  context 'with the filename specified and ending in .conf' do
    recipe do
      user_ulimit 'tomcat' do
        filename 'foo.conf'
        filehandle_soft_limit 8192
      end
    end

    it { is_expected.to create_template('/etc/security/limits.d/foo.conf') }
  end

  context 'with the username set to *' do
    recipe do
      user_ulimit 'tomcat' do
        username '*'
        filehandle_soft_limit 8192
      end
    end

    it { is_expected.to create_template('/etc/security/limits.d/00_all_limits.conf') }
  end
end
